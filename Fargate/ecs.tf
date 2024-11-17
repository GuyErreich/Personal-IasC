# ECS cluster module
module "ecs" {
  source       = "terraform-aws-modules/ecs/aws"
  version      = "~> 5.0"
  cluster_name = "fargate-cluster"

  depends_on = [ aws_iam_policy.ecr_pull_accesses ]

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

  create_task_exec_iam_role = true
  task_exec_iam_role_name = "fargate-cluster"

  services = {
    unreal_engine = {
      cpu               = 8 * 1024
      memory            = 16 * 1096
      desired_count     = 0

      ephemeral_storage = {
        size_in_gib = 70
      }
      
      enable_execute_command = true

      create_task_exec_iam_role = true
      task_exec_iam_role_name = "task_exec_iam_role_name"

      create_security_group = true
      security_group_name = "fargate-service"
      
      create_tasks_iam_role = true
      tasks_iam_role_name = "tasks_iam_role_name"
      tasks_iam_role_policies = {
        ECRAccesses = "${aws_iam_policy.ecr_pull_accesses.arn}"
      }
      
      create_iam_role = true
      iam_role_name = "fargate-service-iam_role_name"

      container_definitions = [
        {
          name                    = "unreal-engine-ci-cd"
          image                   = "961341519925.dkr.ecr.eu-central-1.amazonaws.com/ci-cd/github-runner:latest"
          cpu                     = 4 * 1024
          memory                  = 6 * 1024
          essential               = true
          user                    = "1000"
          readonly_root_filesystem  = false

          # environment = [
          #   {
          #     name  = "SSM_ENABLED"
          #     value = "true"
          #   }
          # ]

          command = [
            "--repo", var.github_org,
            "--token", jsondecode(data.aws_secretsmanager_secret_version.github_runner_token.secret_string)["Token"],
            "--runner-name", "fargate_runner",
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


      subnet_ids = module.vpc.private_subnets

      security_group_rules = {
        egress_all = {
          type = "egress"
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
