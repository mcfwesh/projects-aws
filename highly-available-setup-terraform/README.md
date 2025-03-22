# Highly Available Architecture on AWS using Terraform

## Table of Contents

- [Introduction](#introduction)
- [Web App Overview](#web-app-overview)
- [Terraform Setup](#terraform-setup)
- [Infrastructure Provisioning](#infrastructure-provisioning)
  - [VPC and Networking](#vpc-and-networking)
  - [Security Groups](#security-groups)
  - [PostgreSQL RDS](#postgresql-rds)
  - [IAM Roles](#iam-roles)
  - [Data Sources](#data-sources)
  - [SSM Parameters](#ssm-parameters)
  - [EC2 Bootstrapping](#ec2-bootstrapping)
  - [Load Balancer and Auto Scaling](#load-balancer-and-auto-scaling)
- [Testing and Results](#testing-and-results)
- [Conclusion](#conclusion)

## Introduction

I built a highly available (HA) architecture on AWS using Terraform. The goal was a robust, scalable system that could handle failures gracefully. I used a custom VPC, spanning three availability zones, with a PostgreSQL RDS instance, an auto-scaling group (ASG) of EC2 instances, and a load balancer. Terraform made this whole setup a "one-click" deployment (after the initial setup, of course!). The application is a simple React/Express full-stack app, containerized with Docker.

## Web App Overview

The app is a basic full-stack setup: React frontend, Express backend. It's containerized with Docker, making deployment consistent. The main point of the app is to demonstrate the HA setup – how the load balancer and ASG respond to stress.

## Terraform Setup

I used VSCode and set up a `providers.tf` file to configure AWS as the provider, targeting the `us-east-1` region. I authenticated using AWS access keys (make sure you have those set up!). `terraform init` gets everything ready, and `terraform apply` deploys the infrastructure.

## Infrastructure Provisioning

This is where the magic happens. I've broken down the key components:

### VPC and Networking

- Created a VPC (`10.16.0.0/16` CIDR) with DNS support.
- Added an Internet Gateway (IGW) for public subnet access.
- Set up a route table, directing public traffic to the IGW.
- Created nine subnets (though only six are actively used): three for RDS, three for the web app (public). The public subnets have `map_public_ip_on_launch = true`.
- Associated the public route table with the public subnets.
- _Learned:_ Route tables and routes are separate resources in Terraform, requiring explicit association.

### Security Groups

- Created separate security groups (`security-groups.tf`) for:
  - **React App:** Allows inbound HTTP (port 80) and SSH (port 22).
  - **Database:** Allows inbound PostgreSQL (port 5432) _only_ from the React app's security group.
  - **Load Balancer:** Allows inbound HTTP (port 80) from anywhere.
- This enforces separation of concerns and least privilege.

### PostgreSQL RDS

- Created an RDS subnet group (`db.tf`) spanning the three DB subnets.
- Provisioned a PostgreSQL RDS instance. Key settings:
  - `publicly_accessible = false` (important for security!)
  - Used the first available availability zone.
  - Linked to the DB subnet group and security group.
  - `skip_final_snapshot = true` (for easier cleanup in this demo setup).

### IAM Roles

- Created an IAM role (`roles.tf`) for the EC2 instances: `h20up_react_instance_role`.
- It allows `sts:AssumeRole` for EC2 and includes the `AmazonSSMManagedInstanceCore` policy. This lets the instances fetch DB parameters from SSM.
- Created an instance profile to hold the role.

### Data Sources

- Used data sources (`data_sources.tf`) to:
  - Get the AMI ID for the EC2 instances.
  - Dynamically fetch the availability zones for `us-east-1`.

### SSM Parameters

- Stored DB connection details (host, port, name, username, password) as SSM parameters.
- The password is a `SecureString` for encryption.
- Used a path like `/react-app/parameter-name` for organization.

### EC2 Bootstrapping

- Created a user data script (`react_instance_user_data.tpl`) to run on EC2 instance launch. This script:
  - Fetches DB parameters from SSM.
  - Gets the instance ID.
  - Installs Docker, Docker Compose, and Git.
  - Clones the app's Git repo.
  - Creates an environment file with the DB parameters.
  - Builds and runs the Docker Compose setup.
- _Challenges:_ Getting the SSM parameter fetching right and running Docker Compose with the correct permissions (used `ec2-user` group).

### Load Balancer and Auto Scaling

- Created an application load balancer (`asg-lb.tf`):
  - Enabled cross-zone load balancing.
  - Associated with the defined security group and subnets.
- Created a target group for the load balancer.
- Set up a listener to forward port 80 traffic to the target group.
- Created a key pair for SSH access.
- Defined a launch template for the EC2 instances, including:
  - AMI ID, instance type, key pair, user data script, and instance profile.
- Created an auto-scaling group (ASG):
  - Min size: 1, Desired: 2, Max: 3.
  - Health check type: EC2.
  - Linked to the VPC subnets, launch template, and target group.
- _Challenges:_ Initially missed the listener configuration and the instance profile in the launch template.

## Testing and Results

After `terraform apply`, I tested the setup:

- **Stress Testing 1:** SSHed into an instance and used the `stress` tool. The load balancer quickly switched traffic to another instance.
- **Stress Testing 2:** Terminated an instance. The load balancer detected the failure and redirected traffic after a cooldown period.

This confirmed the HA setup was working as expected.

## Conclusion

Terraform made provisioning this HA architecture on AWS surprisingly straightforward. The combination of AWS services and Terraform's declarative approach provided a powerful and efficient way to build a scalable, fault-tolerant system. The load balancer and ASG worked seamlessly, demonstrating the resilience of the setup. This project reinforced the value of infrastructure-as-code for building robust and maintainable systems.
