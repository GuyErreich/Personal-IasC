# ECS cluster module
module "ecs" {
  source       = "terraform-aws-modules/ecs/aws"
  version      = "~> 5.0"
  cluster_name = "fargate-cluster"

  depends_on = [ aws_iam_policy.ecr_pull_accesses, data.aws_ecr_image.unreal_engine ]

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/fargate-github-runner"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    unreal_engine = {
      cpu           = 4 * 1024
      memory        = 16 * 1024
      desired_count = 0

      ephemeral_storage = {
        size_in_gib = 70
      }

      autoscaling_max_capacity = 10
      autoscaling_min_capacity = 0
      deployment_minimum_healthy_percent = 0

      autoscaling_policies = { }

      enable_execute_command              = true

      create_task_exec_iam_role           = true
      task_exec_iam_role_use_name_prefix  = false
      task_exec_iam_role_name             = "ECSFargateTaskExec"

      create_tasks_iam_role               = true
      tasks_iam_role_use_name_prefix      = false
      tasks_iam_role_name                 = "ECSFargateTasks"

      create_iam_role                     = true
      iam_role_use_name_prefix            = false
      iam_role_name                       = "ECSFargateService"

      create_security_group               = true
      security_group_name                 = "fargate-service"

      tasks_iam_role_policies = {
        ECRAccesses = aws_iam_policy.ecr_pull_accesses.arn
      }


      container_definitions = [
        {
          name                     = "unreal-engine-ci-cd"
          image                    = data.aws_ecr_image.images["unreal_engine"].image_uri
          cpu                      = 4 * 1024
          memory                   = 16 * 1024
          essential                = true
          user                     = "1000" //TODO: test with out it
          readonly_root_filesystem = false //TODO: test with out it

          command = [
            "--repo", var.github_org,
            "--token", jsondecode(data.aws_secretsmanager_secret_version.github_runner_token.secret_string)["Token"],
            "--runner-name", "ue_5.4.4_runner",
            "--labels", "fargate,ue,5.4.4",
            "--ecs-task"
          ]

          port_mappings = [
            {
              name          = "unreal-engine-ci-cd"
              containerPort = 80
              protocol      = "tcp"
            }
          ]

        }
      ]


      subnet_ids       = module.vpc.public_subnets
      assign_public_ip = true

      security_group_rules = {
        egress_all = {
          type        = "egress"
          description = "Allow all outbound traffic"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }


  tags = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "unreal engine"
  }
}

resource "aws_iam_role_policy_attachment" "tasks-iam-roles-ecs-control-attach" {
  depends_on = [ module.ecs,  aws_iam_policy.ecs_update_service_policy]

  for_each = module.ecs.services

  role       = each.value.tasks_iam_role_name
  policy_arn = aws_iam_policy.ecs_update_service_policy.arn
}
