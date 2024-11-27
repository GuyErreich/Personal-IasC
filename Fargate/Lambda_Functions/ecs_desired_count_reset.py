import boto3

ecs = boto3.client('ecs')

def lambda_handler(event, context):
    # cluster_name = "your-cluster-name"
    # service_name = "your-service-name"

    cluster_name = event.get('clusterName')  # Adjust based on the actual event structure
    service_name = event.get('serviceName')  # Adjust based on the actual event structure
    
    # Describe Service
    response = ecs.describe_services(
        cluster=cluster_name,
        services=[service_name]
    )
    
    desired_count = response['services'][0]['desiredCount']
    
    # If only 1 task is running, set desired count to 0
    if desired_count == 1:
        ecs.update_service(
            cluster=cluster_name,
            service=service_name,
            desiredCount=0
        )
        print(f"Set desired count to 0 for service {service_name}")
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
