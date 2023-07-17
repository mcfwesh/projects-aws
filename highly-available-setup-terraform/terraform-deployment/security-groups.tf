// Create a security group for the react app
resource "aws_security_group" "h20up_react_app" {
  name        = "dev_react_app_sg"
  description = "Control access to react instances"
  vpc_id      = aws_vpc.h20up_vpc.id

  ingress {
    description = "Allow HTTP access in"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow SSH access in"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev_react_app_sg"
  }
}

// Create a security group for the db
resource "aws_security_group" "h20up_db_sg" {
  name        = "dev_db_sg"
  description = "Control access to DB instances"
  vpc_id      = aws_vpc.h20up_vpc.id

  ingress {
    description     = "Allow Postgres access in"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.h20up_react_app.id]
  }

  tags = {
    Name = "dev_db_sg"
  }
}

// Create a security group for the load balancer
resource "aws_security_group" "h20up_load_balancer_sg" {
  name        = "dev_load_balancer_sg"
  description = "Control access to load balancer"
  vpc_id      = aws_vpc.h20up_vpc.id

  ingress {
    description = "Allow HTTP access in"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev_load_balancer_sg"
  }
}
