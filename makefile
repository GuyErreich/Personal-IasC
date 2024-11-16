aws ecs update-service \
            --cluster fargate-cluster \
            --service unreal_engine \
            --desired-count 1

aws ecs list-tasks --cluster fargate-cluster

arn:aws:ecs:eu-central-1:961341519925:task/fargate-cluster/f38e8412c44946f2a1a77f813df14ad3q

aws ecs execute-command \
    --cluster fargate-cluster \
    --task 36ac0305321643c7b6dc741773f6ef7b \
    --container unreal-engine-ci-cd \
    --command bash \
    --interactive

    arn:aws:ecs:eu-central-1:961341519925:task/fargate-cluster/45d627ef36db4286a9cebbaa8f12313a