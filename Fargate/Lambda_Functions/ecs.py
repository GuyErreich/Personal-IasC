import boto3
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ecs = boto3.client('ecs')

def reset_desired_count_on_repeating_failure(event, context):
   # Log the received event
    logger.info(f"Received event: {json.dumps(event, indent=2)}")
    
    # Extract the message from the SNS event
    sns_message = event['Records'][0]['Sns']['Message']
    parsed_message = json.loads(sns_message)  # Parse the JSON string into a Python dictionary
    
    # Extract ClusterName and ServiceName from the message
    dimensions = parsed_message['Trigger']['Dimensions']
    cluster_name = next((dim['value'] for dim in dimensions if dim['name'] == 'ClusterName'), None)
    service_name = next((dim['value'] for dim in dimensions if dim['name'] == 'ServiceName'), None)
    
    # Log extracted values
    logger.info(f"Extracted ClusterName: {cluster_name}")
    logger.info(f"Extracted ServiceName: {service_name}")
    
    if not cluster_name or not service_name:
        logger.error("ClusterName or ServiceName not found in the event.")
        return
    
    # Describe Service
    response = ecs.describe_services(
        cluster=cluster_name,
        services=[service_name]
    )
    
    if 'services' in response and response['services']:
        desired_count = response['services'][0]['desiredCount']
        
        # If only 1 task is running, set desired count to 0
        if desired_count == 1:
            ecs.update_service(
                cluster=cluster_name,
                service=service_name,
                desiredCount=0
            )
            print(f"Set desired count to 0 for service {service_name}")
        else:
            print(f"Desired count for service {service_name} is not 1, it is {desired_count}")
    else:
        print(f"Failed to describe service {service_name} in cluster {cluster_name}")
    # optional later if ever needed currently will not give me the results i want
    # else:
    #     # Find failing task and stop it
    #     tasks = ecs.list_tasks(
    #         cluster=cluster_name,
    #         serviceName=service_name
    #     )['taskArns']
        
    #     for task_arn in tasks:
    #         ecs.describe_tasks(cluster=cluster_name, tasks=[task_arn])
    #         ecs.stop_task(cluster=cluster_name, task=task_arn)
    #         print(f"Stopped failing task {task_arn}")
