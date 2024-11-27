import boto3

ecs_client = boto3.client('ecs')

def lambda_handler(event, context):
    cluster_name = 'your-cluster-name'
    service_name = 'your-service-name'

    # Get the running tasks in the service
    response = ecs_client.list_tasks(
        cluster=cluster_name,
        serviceName=service_name,
        desiredStatus='RUNNING'
    )

    task_arns = response['taskArns']

    # Check if there's only one task running
    if len(task_arns) == 1:
        # Get the task details to check its status
        task_details = ecs_client.describe_tasks(
            cluster=cluster_name,
            tasks=task_arns
        )

        task_status = task_details['tasks'][0]['lastStatus']

        # If the task is in a failed state, stop it and scale down
        if task_status == 'STOPPED' and task_details['tasks'][0]['stoppedReason'] == 'EssentialContainerExited':
            ecs_client.update_service(
                cluster=cluster_name,
                service=service_name,
                desiredCount=0
            )
