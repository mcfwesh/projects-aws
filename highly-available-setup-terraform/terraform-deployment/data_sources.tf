data "aws_ami" "ami_server" {
  owners = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.0.20230614.0-kernel-6.1-x86_64"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

