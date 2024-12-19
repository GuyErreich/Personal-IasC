# VPC module (optional, if you need a custom VPC for ECS)
module "vpc" {
  source              = "terraform-aws-modules/vpc/aws"
  version             = "~> 5.0"
  name                = "fargate-vpc"
  cidr                = "10.0.0.0/16"
  azs                 = data.aws_availability_zones.available.names
  public_subnets      = var.public_subnets
  private_subnets     = var.private_subnets

  enable_nat_gateway  = true
  single_nat_gateway  = true
}

# NOTE: if you don't care about the costs you can use the ecs on private subnet in your vpc.
#       if so you will need these end point for debugging and enabling communication between
#       the ECS and the ECR. 

#       might also be smart to add an AWS PrivateLink to increase ECR pull speed for such big images
#       like an UnrealEngine automation image.

# resource "aws_vpc_endpoint" "ssm" {
#   vpc_id              = module.vpc.vpc_id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          =  module.vpc.private_subnets
#   security_group_ids  = [module.vpc.default_security_group_id]
# }

# resource "aws_vpc_endpoint" "ssm_messages" {
#   vpc_id              =  module.vpc.vpc_id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = module.vpc.private_subnets
#   security_group_ids  = [module.vpc.default_security_group_id]
# }

# resource "aws_vpc_endpoint" "ecr" {
#   vpc_id              = module.vpc.vpc_id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = module.vpc.private_subnets
#   security_group_ids  = [aws_security_group.ecr_endpoint_sg.id]
# }

# resource "aws_vpc_endpoint" "ecr_api" {
#   vpc_id              = module.vpc.vpc_id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = module.vpc.private_subnets
#   security_group_ids  = [aws_security_group.ecr_endpoint_sg.id]
# }



# resource "aws_security_group" "ecr_endpoint_sg" {
#   name        = "ecr-endpoint-sg"
#   description = "Security group for ECR VPC endpoints"
#   vpc_id      = module.vpc.vpc_id

#   # Allow inbound traffic from ECS task security group
#   ingress {
#     description      = "Allow ECS task access"
#     from_port        = 443
#     to_port          = 443
#     protocol         = "tcp"
#     security_groups  = [module.ecs.services["unreal_engine"].security_group_id] # Replace with your ECS SG
#   }

#   # Allow all outbound traffic (required for interface endpoints)
#   egress {
#     description = "Allow all outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "ecr-endpoint-sg"
#   }
# }