import boto3
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)
cloudwatch = boto3.client('cloudwatch')

def generate_metrics_for_failure_alarm(event, context):
    logger.info(f"Received event: {json.dumps(event, indent=2)}")

    detail = event.get('detail', {})
    stopped_reason = detail.get('stoppedReason')
    containers = detail.get('containers', [])
    
    # Check if 'Essential container in task exited' and exit code != 0
    for container in containers:
        exit_code = container.get('exitCode', 0)
        reason = container.get('reason', '')

        if stopped_reason == "Essential container in task exited" and exit_code != 0:
            cluster_name = detail.get('clusterArn', 'unknown')
            service_name = detail.get('group', '').split(':')[-1]  # Extract service name

            logger.info(f"Non-zero exit code detected. Cluster: {cluster_name}, Service: {service_name}, ExitCode: {exit_code}")
            
            try:
                cloudwatch.put_metric_data(
                    Namespace='ECS/TaskFailures',
                    MetricData=[
                        {
                            'MetricName': 'EssentialContainerExited',
                            'Dimensions': [
                                {'Name': 'ClusterName', 'Value': cluster_name},
                                {'Name': 'ServiceName', 'Value': service_name}
                            ],
                            'Value': 1,
                            'Unit': 'Count'
                        }
                    ]
                )
                logger.info("Metric published successfully.")
            except Exception as e:
                logger.error(f"Failed to publish metric: {e}")
        else:
            logger.info("No matching conditions found.")
