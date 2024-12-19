import json
import boto3
import hmac
import hashlib
import os
import requests
from utils import Logger

# Initialize ECS client
ecs_client = boto3.client('ecs')

# Environment variables (set these in your Lambda configuration)
CLUSTER_NAME = os.environ['CLUSTER_NAME']
SERVICE_NAME = os.environ['SERVICE_NAME']
GITHUB_WEBHOOK_TOKEN = os.environ['GITHUB_WEBHOOK_TOKEN']
GITHUB_ACCESSES_TOKEN = os.environ['GITHUB_ACCESSES_TOKEN']
AVAILABLE_ACTIONS = ['push', 'workflow_dispatch']

logger = Logger(name="github_webhook")



def generate_hmac_signature(payload):
    logger.set_function_title("generate_hmac_signature")

    logger.info("Creating HMAC signature for validation.")
    hashed = hmac.new(GITHUB_WEBHOOK_TOKEN.encode('utf-8'), payload.encode('utf-8'), hashlib.sha256)
    
    return f"sha256={hashed.hexdigest()}"


def validate_signature(payload, signature):
    logger.set_function_title("validate_signature")

    try:
        logger.info(f"Validating signature... Incoming: {signature}")
        expected_signature = generate_hmac_signature(payload)

        if hmac.compare_digest(expected_signature, signature):
            logger.info("Signature validated successfully.")
            return True

        logger.error("Signature validation failed.")

        return False

    except Exception as e:
        logger.error(f"Error during signature validation: {e}")
        raise


def fetch_github_runners(repo, headers):
    runners = []
    page = 1

    while True:
        response = requests.get(
            f'https://api.github.com/repos/{repo}/actions/runners',
            headers=headers,
            params={'per_page': 100, 'page': page}
        )

        if response.status_code != 200:
            logger.error(f"Failed to fetch runners (Page {page}): {response.text}")
            return []  # Return an empty list on failure

        page_runners = response.json().get('runners', [])
        if not page_runners:
            logger.info(f"No more runners found on page {page}.")
            break  # No more pages

        runners.extend(page_runners)
        page += 1

    if not runners:
        logger.info(f"No runners found for repository {repo}.")  # Add context if needed
        return []

    logger.info(f"Fetched a total of {len(runners)} runners.")
    return runners


def check_available_runners(body):
    """Check if there are available runners for the repository and match them to running ECS tasks."""
    logger.set_function_title("check_available_runners")

    # Step 1: List ECS tasks in the specified cluster and service
    tasks = ecs_client.list_tasks(
        cluster=CLUSTER_NAME,
        serviceName=SERVICE_NAME
    )['taskArns']

    if not tasks:
        logger.info("No ECS tasks found.")
        return False 

    # Step 2: Retrieve task details to correlate with runners
    task_details = ecs_client.describe_tasks(cluster=CLUSTER_NAME, tasks=tasks)['tasks']
    running_task_ids = {task['taskArn'].split('/')[-1] for task in task_details if task['lastStatus'] == 'RUNNING'}

    # Step 3: Fetch all GitHub runners
    headers = {'Authorization': f'Bearer {GITHUB_ACCESSES_TOKEN}'}
    repo = body['event_data']['repository']['full_name']
    runners = fetch_github_runners(repo, headers)

    # Step 4: Match runners with running ECS tasks
    for runner in runners:
        if runner['status'] == 'online' and not runner['busy']:
            runner_tags = [label['name'] for label in runner.get('labels', [])]
            logger.info(f"Runner {runner['name']} has tags: {runner_tags}")
            matching_tasks = [task_id for task_id in running_task_ids if task_id in runner_tags]

            if matching_tasks:
                logger.info(f"Available runner matches running task via tag: {runner['name']} -> Task IDs: {matching_tasks}")
                return True 
            else:
                logger.info(f"Runner {runner['name']} has no matching task ID in its tags.")

    logger.info("No available runners matched any running ECS tasks.")
    return False


def scale_ecs_service():
    logger.set_function_title("scale_ecs_service")

    try:
        response = ecs_client.describe_services(
            cluster=CLUSTER_NAME,
            services=[SERVICE_NAME]
        )
        
        current_count = response['services'][0]['desiredCount']
        new_count = current_count + 1

        ecs_client.update_service(
            cluster=CLUSTER_NAME,
            service=SERVICE_NAME,
            desiredCount=new_count
        )

        logger.info(f"Scaled ECS service {SERVICE_NAME} to {new_count} tasks.")

        return new_count

    except Exception as e:
        logger.error(f"Error scaling ECS service: {str(e)}")
        raise


def handler(event, context):
    logger.set_function_title("handler")
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Validate incoming headers
    github_signature = event.get('headers', {}).get('X-Hub-Signature-256')
    if not github_signature:
        logger.warning("Missing X-Hub-Signature-256 header.")
        return {"statusCode": 400, "body": "Missing X-Hub-Signature-256 header"}

    logger.info("Validating signature...")
    # Parse and validate payload
    payload = event['body']
    if not validate_signature(payload, github_signature):
        return {"statusCode": 403, "body": "Invalid signature"}

    # Parse the JSON payload
    body = json.loads(payload)
    action = event['headers'].get('X-GitHub-Event')
    logger.info(f"GitHub webhook action: {action}")

    if action not in AVAILABLE_ACTIONS: 
        logger.info(f"Ignoring action: {action}")
        return {"statusCode": 200, "body": f"Ignoring action: {action}"}

     # Check available runners
    if check_available_runners(body):
        return {"statusCode": 200, "body": "Found available runners; no scaling needed."}

    # Scale the ECS service
    try:
        new_desired_count = scale_ecs_service()
        return {
            "statusCode": 200,
            "body": f"Scaled service {SERVICE_NAME} to {new_desired_count} tasks."
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"Error scaling ECS service: {str(e)}"
        }
