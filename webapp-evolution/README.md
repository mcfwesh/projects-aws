# Scaling WordPress: Building a Resilient Architecture

## Table of Contents

- [Introduction](#introduction)
- [Stage 1: Creating the VPC Using CloudFormation](#stage-1-creating-the-vpc-using-cloudformation)
- [Stage 2: Initial WordPress Setup and Limitations](#stage-2-initial-wordpress-setup-and-limitations)
- [Stage 3: Streamlining Instance Launch and Configuration](#stage-3-streamlining-instance-launch-and-configuration)
- [Stage 4: Database Migration to Amazon RDS](#stage-4-database-migration-to-amazon-rds)
- [Stage 5: Implementing Highly Available File Storage with Amazon EFS](#stage-5-implementing-highly-available-file-storage-with-amazon-efs)
- [Stage 6: Implementing Autoscaling and Load Balancing](#stage-6-implementing-autoscaling-and-load-balancing)

## Introduction

This blog post details the evolution of a WordPress architecture, from a single-instance setup (application and database together) to a scalable, resilient system capable of handling increased demand and ensuring high availability. We'll use various AWS services to achieve this.

## Stage 1: Creating the VPC Using CloudFormation

We started by creating a Virtual Private Cloud (VPC) using AWS CloudFormation. This automated the provisioning of networking resources (subnets, route tables, security groups, internet gateways) for our WordPress web server. CloudFormation provides a consistent and reproducible way to define infrastructure. The VPC creates a secure, isolated network for our application.

## Stage 2: Initial WordPress Setup and Limitations

We deployed WordPress and its MariaDB database on a single Amazon EC2 instance within the VPC. We used AWS Systems Manager (SSM) Parameter Store to store and retrieve configuration parameters. We installed updates, Apache, set up the MariaDB password, downloaded and configured WordPress, and created the admin user.

This initial setup had several limitations:

- **Slow Performance:** Database and server on the same instance.
- **Security Risk:** Direct client connections to the instance.
- **No Health Checks:** Susceptible to failures.
- **No Scaling/Failover:** IP changes on restart could break the database connection.

## Stage 3: Streamlining Instance Launch and Configuration

We improved instance launch and configuration using launch templates. We moved the manual setup commands (from Stage 2) into the user-data field of the launch template. This allows us to create new instances with pre-configured WordPress settings quickly. We tested this, confirming the initial configuration and post creation worked.

The database and web server were _still_ on the same instance, but we eliminated the manual setup steps.

## Stage 4: Database Migration to Amazon RDS

We migrated the database from the EC2 instance to an Amazon RDS instance. This addresses the single-instance limitation, improving scalability and resilience.

The migration involved:

1.  Creating an RDS subnet group.
2.  Creating the RDS instance, using the same database parameters from SSM.
3.  Backing up the local MariaDB data (using `mysqldump`).
4.  Updating the DB endpoint in SSM from "localhost" to the new RDS endpoint.
5.  Restoring the backup to the RDS instance.
6.  Updating WordPress configuration files to point to the RDS instance.

We stopped the local MariaDB service and tested the WordPress site, confirming data integrity. This separation of database and web server improves scalability and reliability.

## Stage 5: Implementing Highly Available File Storage with Amazon EFS

We isolated file-based data (images) from the WordPress server using Amazon Elastic File System (EFS). EFS provides a highly available, shared file system accessible to all instances.

We created the EFS file system, configured mount points in each availability zone, and stored the file system ID in SSM. We then connected the EFS to the WordPress instance:

1.  Installed EFS mount helper packages.
2.  Added the EFS ID (from SSM) to the instance.
3.  Mounted the EFS.
4.  Moved data from the instance to the EFS mount point.
5.  Set appropriate permissions.
6.  Rebooted and tested.

We confirmed images were served from EFS, eliminating data loss risk on web server failure. We also updated the launch template to automate the EFS mount, preparing for a fully automated instance setup.

## Stage 6: Implementing Autoscaling and Load Balancing

We implemented an autoscaling group (ASG) and a load balancer to increase resilience and availability. This addresses the security risks of direct instance access and adds self-healing capabilities.

1.  **Load Balancer:** Created a load balancer with a target group for the instances launched by the ASG. The load balancer's DNS name was stored in SSM.
2.  **Autoscaling Group:** Created the ASG using the evolved launch template. We attached the load balancer, enabled health checks, and configured metrics collection in CloudWatch.
3.  **ASG Configuration:** Set minimum, desired, and maximum capacity to one instance initially. A new instance was automatically launched when the previous one was terminated.
4.  **Automatic Scaling:** Implemented two scaling policies based on average CPU utilization (threshold of 40%). The ASG adds a capacity unit when CPU utilization exceeds 40% and removes one when it falls below 40%. We set the maximum capacity to three instances.
5.  **Testing**: We stressed the instance and confirmed that the ASG added a new instance.

The load balancer provides a secure entry point, and the ASG provides automatic healing.

## Conclusion

We successfully evolved a single-instance WordPress setup into a resilient and scalable architecture using AWS services. This journey demonstrates the power of infrastructure-as-code and best practices for building highly available systems.
