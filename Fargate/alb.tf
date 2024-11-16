# module "alb" {
#   source          = "terraform-aws-modules/alb/aws"
#   name            = "fargate"
#   internal        = false  # Set to true if you want an internal load balancer
#   security_groups = [aws_security_group.fargate_alb.id]
#   subnets         = module.vpc.public_subnets

#   enable_deletion_protection = false

#   enable_http2 = true

#   tags = {
#   }
# }


# resource "aws_lb_target_group" "fargat" {
#   name     = "fargat"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = module.vpc.vpc_id

#   health_check {
#     path                = "/"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#   }
# }

# resource "aws_lb_listener" "fargat_http" {
#   load_balancer_arn = module.alb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type = "fixed-response"
#     fixed_response {
#       status_code = 200
#       content_type = "text/plain"
#       message_body = "Hello, world"
#     }
#   }
# }

# resource "aws_lb_listener" "fargat_https" {
#   load_balancer_arn = module.alb.arn
#   port              = 443
#   protocol          = "HTTPS"

#   certificate_arn   = aws_acm_certificate.fargat_https_certificate.arn

#   default_action {
#     type = "fixed-response"
#     fixed_response {
#       status_code = 200
#       content_type = "text/plain"
#       message_body = "Hello, world"
#     }
#   }
# }

# resource "aws_lb_listener_certificate" "fargat_https_certificate" {
#   listener_arn    = aws_lb_listener.fargat_https.arn
#   certificate_arn = aws_acm_certificate.fargat_https_certificate.arn
# }

# resource "aws_acm_certificate" "fargat_https_certificate" {
#   domain_name = "example.com"
#   validation_method = "DNS"

#   # Optionally, add subject alternative names (SANs) for multi-domain SSL certificates
#   subject_alternative_names = ["www.example.com"]  

#   tags = {
#     Name = "example.com certificate"
#   }
# }

# resource "aws_route53_zone" "example" {
#   name = "example.com"
# }

# resource "aws_route53_record" "fargat_cert_validation" {
#   for_each = { for dvo in aws_acm_certificate.fargat_https_certificate.domain_validation_options : dvo.domain_name => dvo }

#   zone_id = aws_route53_zone.example.zone_id
#   name    = each.value.resource_record_name
#   type    = each.value.resource_record_type
#   ttl     = 60
#   records = [each.value.resource_record_value]
# }

# resource "aws_acm_certificate_validation" "fargat_https_validation" {
#   certificate_arn         = aws_acm_certificate.fargat_https_certificate.arn
#   validation_record_fqdns = [for record in aws_route53_record.fargat_cert_validation : record.fqdn]
# }

# resource "aws_security_group" "fargate_alb" {
#   name        = "fargate_alb_sg"
#   description = "Allow HTTP and HTTPS inbound traffic"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#   }
# }
