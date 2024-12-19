resource "aws_iam_role" "lambda_exec" {
  name = "lambda_${var.lambda_function_name}_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_${var.lambda_function_name}_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Action   = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:logs:*:*:*"
        }
      ],
      # Add dynamic policies here
      flatten([
        for policy in var.lambda_iam_role_policies : {
          Action   = policy.Action
          Effect   = policy.Effect
          Resource = flatten(policy.Resource)  # Flatten the resources if they're lists
        }
      ])
    )
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}