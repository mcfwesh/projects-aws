// Create an instance role for the react instance
resource "aws_iam_role" "h20up_react_instance_role" {
  name                = "react_instance_role"
  path                = "/"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  }, )

  tags = {
    tag-key = "dev_react_instance_role"
  }
}

// Create an instance profile for the react instance
resource "aws_iam_instance_profile" "h20up_react_instance_profile" {
  name = "react_instance_profile"
  path = "/"
  role = aws_iam_role.h20up_react_instance_role.name

  tags = {
    tag-key = "dev_react_instance_profile"
  }
}
