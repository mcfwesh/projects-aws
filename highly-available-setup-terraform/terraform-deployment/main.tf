// This is the main configuration file for the Terraform deployment.

// Create a VPC with a /16 CIDR block
resource "aws_vpc" "h20up_vpc" {
  cidr_block           = "10.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dev"
  }
}

// Create an internet gateway for the VPC
resource "aws_internet_gateway" "h20up_igw" {
  vpc_id = aws_vpc.h20up_vpc.id

  tags = {
    Name = "dev_igw"
  }
}

// Create a route table for the VPC
resource "aws_route_table" "h20up_pub_rt_table" {
  vpc_id = aws_vpc.h20up_vpc.id

  tags = {
    Name = "dev_rt"
  }
}

// Create a route in the route table that points all traffic (public) to the internet gateway
resource "aws_route" "h20up_pub_rt" {
  route_table_id         = aws_route_table.h20up_pub_rt_table.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_internet_gateway.h20up_igw]
  gateway_id             = aws_internet_gateway.h20up_igw.id
}

// Create DB subnet a
resource "aws_subnet" "h20up_db_subnet_a" {
  vpc_id            = aws_vpc.h20up_vpc.id
  cidr_block        = "10.16.16.0/20"
  availability_zone = element(data.aws_availability_zones.available.names, 0)

  tags = {
    Name = "dev_db_subnet_a"
  }
}

// Create DB subnet b
resource "aws_subnet" "h20up_db_subnet_b" {
  vpc_id            = aws_vpc.h20up_vpc.id
  cidr_block        = "10.16.80.0/20"
  availability_zone = element(data.aws_availability_zones.available.names, 1)

  tags = {
    Name = "dev_db_subnet_b"
  }
}

// Create DB subnet c
resource "aws_subnet" "h20up_db_subnet_c" {
  vpc_id            = aws_vpc.h20up_vpc.id
  cidr_block        = "10.16.144.0/20"
  availability_zone = element(data.aws_availability_zones.available.names, 2)

  tags = {
    Name = "dev_db_subnet_c"
  }
}

// Create app subnet a
resource "aws_subnet" "h20up_app_subnet_a" {
  vpc_id            = aws_vpc.h20up_vpc.id
  cidr_block        = "10.16.32.0/20"
  availability_zone = element(data.aws_availability_zones.available.names, 0)

  tags = {
    Name = "dev_app_subnet_a"
  }
}

// Create app subnet b
resource "aws_subnet" "h20up_app_subnet_b" {
  vpc_id            = aws_vpc.h20up_vpc.id
  cidr_block        = "10.16.96.0/20"
  availability_zone = element(data.aws_availability_zones.available.names, 1)

  tags = {
    Name = "dev_app_subnet_b"
  }
}

// Create app subnet c
resource "aws_subnet" "h20up_app_subnet_c" {
  vpc_id            = aws_vpc.h20up_vpc.id
  cidr_block        = "10.16.160.0/20"
  availability_zone = element(data.aws_availability_zones.available.names, 2)

  tags = {
    Name = "dev_app_subnet_c"
  }
}

// Create public subnet a
resource "aws_subnet" "h20up_pub_subnet_a" {
  vpc_id                  = aws_vpc.h20up_vpc.id
  cidr_block              = "10.16.48.0/20"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, 0)

  tags = {
    Name = "dev_pub_subnet_a"
  }
}

// Create public subnet b
resource "aws_subnet" "h20up_pub_subnet_b" {
  vpc_id                  = aws_vpc.h20up_vpc.id
  cidr_block              = "10.16.112.0/20"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, 1)

  tags = {
    Name = "dev_pub_subnet_b"
  }
}

// Create public subnet c
resource "aws_subnet" "h20up_pub_subnet_c" {
  vpc_id                  = aws_vpc.h20up_vpc.id
  cidr_block              = "10.16.176.0/20"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, 2)

  tags = {
    Name = "dev_pub_subnet_c"
  }
}

// Associate the route table with the public subnet a
resource "aws_route_table_association" "h20up_pub_subnet_a_rt_association" {
  subnet_id      = aws_subnet.h20up_pub_subnet_a.id
  route_table_id = aws_route_table.h20up_pub_rt_table.id
}

// Associate the route table with the public subnet b
resource "aws_route_table_association" "h20up_pub_subnet_b_rt_association" {
  subnet_id      = aws_subnet.h20up_pub_subnet_b.id
  route_table_id = aws_route_table.h20up_pub_rt_table.id
}

// Associate the route table with the public subnet c
resource "aws_route_table_association" "h20up_pub_subnet_c_rt_association" {
  subnet_id      = aws_subnet.h20up_pub_subnet_c.id
  route_table_id = aws_route_table.h20up_pub_rt_table.id
}















