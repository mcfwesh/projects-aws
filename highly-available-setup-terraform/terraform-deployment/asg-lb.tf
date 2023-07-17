// Create a load balancer for the react instance
resource "aws_lb" "h20up_load_balancer" {
  name                             = "dev-load-balancer"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.h20up_load_balancer_sg.id]
  subnets                          = [aws_subnet.h20up_pub_subnet_a.id, aws_subnet.h20up_pub_subnet_b.id, aws_subnet.h20up_pub_subnet_c.id]
  enable_cross_zone_load_balancing = true
  tags = {
    Name = "dev_load_balancer"
  }
}

// Create an lb target group for the react instance
resource "aws_lb_target_group" "h20up_target_group" {
  name     = "dev-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.h20up_vpc.id

  health_check {
    path = "/"
  }

  tags = {
    Name = "dev_target_group"
  }
}

// Create a listener for the react instance
resource "aws_lb_listener" "h20up_listener" {
  load_balancer_arn = aws_lb.h20up_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.h20up_target_group.arn
    type             = "forward"
  }
}

// Create a key pair for the react instance
resource "aws_key_pair" "h20up_react_instance_key_pair" {
  key_name   = "react_instance_key_pair"
  public_key = file("/Users/nate/.ssh/react_instance_key.pub")

  tags = {
    tag-key = "dev_react_instance_key_pair"
  }
}

// Create a launch template for the react instance
resource "aws_launch_template" "h20up_launch_template" {
  name_prefix   = "dev_launch_template"
  image_id      = data.aws_ami.ami_server.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.h20up_react_instance_key_pair.key_name
  user_data     = filebase64("react_instance_user_data.tpl")
  iam_instance_profile {
    name = aws_iam_instance_profile.h20up_react_instance_profile.name
  }
  vpc_security_group_ids = [aws_security_group.h20up_react_app.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "dev_launch_template"
    }
  }
}

// Create an autoscaling group for the react instance
resource "aws_autoscaling_group" "h20up_asg" {
  name                      = "dev_asg"
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 2
  health_check_type         = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier       = [aws_subnet.h20up_pub_subnet_a.id, aws_subnet.h20up_pub_subnet_b.id, aws_subnet.h20up_pub_subnet_c.id]

  launch_template {
    id      = aws_launch_template.h20up_launch_template.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.h20up_target_group.arn]

  depends_on = [aws_ssm_parameter.db_host, aws_ssm_parameter.db_port, aws_ssm_parameter.db_name, aws_ssm_parameter.db_username, aws_ssm_parameter.db_password]

  tag {
    key                 = "Name"
    value               = "dev_asg"
    propagate_at_launch = true
  }

}

