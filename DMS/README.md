# Database Migration from On-Premises to AWS

## Table of Contents

- [Introduction](#introduction)
- [Stage 1: Cloud Formation Stack Deployment](#stage-1-cloud-formation-stack-deployment)
- [Stage 2: VPC Peering and Route Configuration](#stage-2-vpc-peering-and-route-configuration)
- [Stage 3: Web Server Migration to AWS](#stage-3-web-server-migration-to-aws)
- [Stage 4: Database Migration to AWS](#stage-4-database-migration-to-aws)
- [Conclusion](#conclusion)

## Introduction

Migrating a database from on-premises to AWS is a crucial step in modernizing your infrastructure and unlocking the benefits of cloud computing. One effective approach for this migration is utilizing the AWS Database Migration Service (DMS). DMS provides a reliable, efficient, and secure solution for transferring your database to the cloud seamlessly. In this blog post, I will share my experience and insights as I undertake the journey of migrating a web application with a Maria DB database from on-premises to AWS architecture involving an EC2 webserver and an RDS MariaDB database using DMS.

## Stage 1: Cloud Formation Stack Deployment

To kick off the migration project, I began by deploying a CloudFormation stack that laid the foundation for both the AWS environment and the simulated on-premises environment. This stack encompassed various logical resources essential for the project's success.

First and foremost, I provisioned a Virtual Private Cloud (VPC), which served as the networking backbone for the entire infrastructure. Within the VPC, I created subnets, security groups, and internet gateways, enabling secure communication and connectivity between the different components.

Next, I deployed EC2 instances to host the on-premises database and the web application. These instances played a crucial role in simulating the on-premises environment within AWS, facilitating a smooth database migration process.

To ensure proper access and permissions, I defined instance roles that all participating instances would assume. These roles were designed to grant the necessary privileges and permissions required for the migration tasks and interactions with AWS services.

Among the notable parameters configured during this stage were the database secrets. These secrets would be instrumental in securely accessing and managing the databases throughout the migration journey, prioritizing data protection and compliance.

With the CloudFormation stack deployment completed, I had established the fundamental infrastructure components required for the subsequent stages of the on-premises database migration project. In the next phase, I would focus on setting up the AWS Database Migration Service (DMS) and initiating the data transfer process. Stay tuned as we delve into the intricacies of configuring DMS and ensuring a seamless database migration experience.

## Stage 2: VPC Peering and Route Configuration

In the second stage of the on-premises database migration project, I focused on establishing seamless connectivity between the simulated on-premise VPC and the AWS VPC. This involved creating VPC peering connections and configuring route tables for effective routing.

To begin, I set up VPC peering connections between the simulated on-premise VPC and the AWS VPC. This allowed the two VPCs to communicate securely with each other, leveraging private IP addresses.

Once the VPC peering connections were established, I turned my attention to configuring the individual route tables for the subnets within the different VPCs. This step was crucial in determining how network traffic would flow between the environments.

In the AWS VPC, I configured the route tables to include the on-premises public IP address as a destination. By doing so, any requests destined for the on-premises environment would be properly routed through the VPC peering connection.

Conversely, I configured the route tables in the on-premises VPC to include the AWS public IP address as a destination. This ensured that any requests originating from the on-premises environment, such as the web application, would be correctly directed to the AWS resources via the VPC peering connection.

By meticulously configuring the routes in the respective VPCs, I established a reliable and secure network communication channel between the simulated on-premise environment and AWS. This paved the way for smooth data transfer and synchronization during the subsequent stages of the database migration project.

In the next stage, I will delve into the setup and configuration of the AWS Database Migration Service (DMS), a pivotal component in transferring the database from on-premises to the AWS cloud. Join me as we explore the intricacies of configuring DMS and initiating the migration process.

## Stage 3: Web Server Migration to AWS

In the third stage of the on-premises database migration project, I focused on migrating the web server from the on-premises environment to AWS. Here's a step-by-step breakdown of the migration process:

Launching the AWS Web Server:

I launched an EC2 instance named "awsCatWeb" to host the web server in AWS.
The instance was launched in the appropriate subnet and availability zone, which were previously set up by the CloudFormation stack.
Installing Apache and MariaDB SQL Tools:

I installed the Apache web server and MariaDB SQL tools on the "awsCatWeb" instance using the command: yum -y install httpd mariadb.
To enable PHP for WordPress configuration, I used the command: amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2.
After installation, I restarted the instance to ensure the changes took effect.
Manual Configuration for On-Premises Database Authentication:

Since the AWS web server still needed to query the on-premises database instance (as the migration to RDS was pending), I manually configured the DB password for authentication on the AWS web server.
I modified the /etc/ssh/sshd_config file to enable password authentication by changing PasswordAuthentication no to PasswordAuthentication yes.
I set a password for the ec2-user using the passwd ec2-user command. The DB password, which was a parameter used in the CloudFormation stack creation, was copied and used as the password. It corresponds to the DB password of the on-premises database.
After making these changes, I restarted the server once again. It's important to note that this manual configuration is not recommended in production due to security reasons. However, it was done here to avoid mistakes during the migration process.
Copying Files and Verifying Web Server Migration:

I SSHed into the on-premises web server and used SCP to copy the files to the AWS web server using its private IP.
Moving into the AWS web server, I verified that the copied files existed.
Finally, I copied the files into the webroot of the "awsCatWeb" instance to ensure they were accessible for the web server.
Fixing File Permissions:

To ensure proper accessibility, I fixed the file permissions on the recently copied documents, allowing them to be accessed by the webroot folder.
Confirming Successful Web Server Migration:

To confirm a successful web server migration, I accessed the public IP address of the AWS web server from a browser.
The browser displayed the WordPress site, similar to that of the on-premises web server, indicating a successful migration.
By successfully migrating the web server to AWS, I had taken a significant step towards achieving a fully functional and scalable cloud-based infrastructure. In the next stage, I will delve into the process of migrating the database itself using the AWS Database Migration Service (DMS). Join me as we explore the intricacies of setting up DMS and executing the database migration

## Stage 4: Database Migration using AWS Database Migration Service (DMS)

In the final stage of the on-premises database migration project, I focused on migrating the database itself using the AWS Database Migration Service (DMS). Here's a step-by-step breakdown of the migration process:

Creating Subnet Groups and Provisioning RDS MariaDB:

I created subnet groups where the RDS MariaDB would reside, ensuring proper network isolation and availability.
Using the AWS Management Console, I proceeded to create the RDS MariaDB instance with the necessary configurations, such as instance size, storage, and security settings.
Setting up Replication Instance and Endpoints:

In the DMS console, I created a replication instance, which is an EC2 instance responsible for handling the replication tasks.
Next, I created two endpoints: the source DB (on-premises) endpoint and the target DB (AWS) endpoint. These endpoints act as containers for the replication instance to conduct the migration process.
To ensure functionality, I tested the newly created endpoints to verify their connectivity and accessibility.
Configuring and Executing Replication Task:

Using the DMS console, I created a replication task, which involved setting up parameters for the replication instance to use. This included specifying the endpoint details for the source and target databases, selecting tables and schemas for migration, and configuring any necessary transformations or mappings.
Once the replication task was configured, I ran it, initiating the replication process between the on-premises database and the AWS RDS instance.
After some time, the replication task successfully completed, ensuring that data from the on-premises database was replicated to the RDS instance in AWS.
Updating Web Server and WordPress Configuration:

I SSHed into the AWS web server instance and updated the on-premises DB hostname used by the web server to access the database. It was replaced with the new RDS instance hostname.
Additionally, I updated the WordPress database inside the web server, replacing the on-premises DB hostname with the RDS instance hostname.
Testing the AWS Web Server with the RDS Instance:

To ensure the functionality of the AWS web server and its ability to fetch data from the newly provisioned RDS instance, I stopped the on-premises infrastructure, including the web server and the database.
I accessed the AWS web server using its public IP and confirmed that everything worked as expected. The website displayed the desired data, indicating a successful migration from the on-premises database to the RDS instance in AWS.

## Conclusion

At this point, I have created a VPC peer between the simulated On-premises environment and AWS. I have successfully migrated the WordPress application files from on-premises (simulated) into AWS. Additionally, I have provisioned an RDS DB Instance and utilized DMS to perform a simple migration of the database from on-premises (simulated) to AWS. By completing the database migration process using the AWS Database Migration Service, I achieved a seamless transition from the on-premises infrastructure to a cloud-based architecture.
