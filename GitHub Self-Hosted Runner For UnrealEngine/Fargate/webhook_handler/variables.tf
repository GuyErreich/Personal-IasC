variable "lambda_zip_path" {
  description = "Path to the Lambda zip file"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_handler" {
  description = "Lambda handler function"
  type        = string
}

variable "lambda_layers" {
  description = "Lambda handler function"
  type        = list(string)
  default = []
}


variable "lambda_iam_role_policies" {
  description = "List of additional Lambda IAM role policies"
  type = list(object({
    Effect   = string
    Action   = list(string)
    Resource = list(string)
  }))
  default = []
}

variable "runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.9"
}

variable "timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  default     = 15
}

variable "lambda_function_env_vars" {
  description = "GitHub webhook secret"
  type        = map
}

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}
