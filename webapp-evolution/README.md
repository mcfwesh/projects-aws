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

In this blog post, we'll embark on an exciting journey to evolve the architecture of a popular web application, WordPress. We'll begin our adventure with a manually built single instance, where both the application and database reside. However, our ultimate goal is to transform this initial setup into a scalable and resilient architecture that can handle increasing demands and ensure high availability. Join me as we explore the evolutionary steps that will empower our WordPress application to thrive in a dynamic and ever-expanding environment.

## Stage 1: Creating the VPC Using CloudFormation

To lay the foundation for our evolving WordPress architecture, the first stage involved creating a Virtual Private Cloud (VPC) using AWS CloudFormation. By leveraging the power of CloudFormation templates, we were able to automate the provisioning of networking resources required for our WordPress web server.

The CloudFormation template provided a declarative way to define our VPC infrastructure, including subnets, route tables, security groups, and internet gateways. This streamlined approach not only saved time but also ensured consistency and reproducibility in our environment setup.

With the VPC in place, we established a secure and isolated network environment for our WordPress web server to operate within. This initial step laid the groundwork for future stages, where we will gradually enhance the architecture to achieve scalability and resilience.

In the next stage, we will delve deeper into deploying the WordPress web server within the VPC and configuring the necessary resources to make it accessible to users. Stay tuned as we explore the next phase of our AWS-powered WordPress architecture evolution.

## Stage 2: Initial WordPress Setup and Limitations

In the second stage of our WordPress architecture evolution, we focused on deploying and configuring the WordPress site along with its MariaDB database. Although the initial setup provided basic functionality, it also revealed several limitations that needed to be addressed to enhance the architecture's scalability and resilience.

To begin, we created an Amazon EC2 instance within the VPC we previously built, housing both the WordPress site and the MariaDB database. We leveraged the saved VPC parameters from the AWS Systems Manager (SSM) parameter store, which facilitated hierarchical storage of parameters and secrets for convenient retrieval.

Connecting to the instance, we proceeded to install updates and the Apache web server. We ensured that the server automatically started without manual intervention. Additionally, we set up the MariaDB password and downloaded, extracted, and configured WordPress. Permissions for all downloaded files were appropriately fixed.

Furthermore, we created the WordPress admin user, providing it with a secure password. We also established the database and configured permissions accordingly. To verify the successful installation, we accessed the WordPress site through the instance's public IP and performed initial configuration, setting up the admin parameters.

Despite the progress made, it became evident that the architecture had several limitations. Firstly, the setup was relatively slow, as the database and server resided on the same instance. Secondly, clients could directly connect to the instance, increasing the risk of security vulnerabilities. Additionally, there were no health checks implemented, leaving the system susceptible to failures. Lastly, the lack of scaling mechanisms and failover solutions posed challenges, particularly when the instance restarted, potentially resulting in a loss of connection to the database due to IP changes.

To overcome these limitations and ensure a scalable and resilient architecture, we will continue our journey by exploring advanced AWS services and architectural patterns. Stay tuned as we evolve the WordPress architecture, addressing these challenges and transforming it into a highly performant and fault-tolerant system.

## Stage 3: Streamlining Instance Launch and Configuration

In the third stage of our WordPress architecture evolution, we focused on enhancing the instance launch and configuration process using launch templates. This approach allowed us to simplify the setup by inputting the commands previously executed manually into the user-data field of the launch template. Additionally, the use of launch templates enabled the effortless creation of new instances with pre-configured WordPress settings.

By leveraging launch templates, we eliminated the need for laborious manual input of user details after instance creation. This significantly streamlined the process, saving time and effort. Testing the newly created instances, we confirmed that everything worked smoothly, including the initial configuration and the ability to make new posts.

While significant improvements were made, it's important to note that one limitation still remained: the database and web server were still hosted on the same instance. However, by utilizing launch templates, we successfully addressed the previous limitation of the manual and time-consuming task of inputting commands for the initial WordPress and database configuration on the EC2 instance.

As we progress further in our architecture evolution, we will explore strategies to separate the database and web server components, enhancing scalability, security, and fault tolerance. Join us in the next stage as we dive deeper into AWS services and architectural patterns to overcome these remaining challenges and create a more robust and scalable WordPress architecture.

## Stage 4: Database Migration to Amazon RDS

In the fourth stage of our WordPress architecture evolution, we focused on migrating the database from the EC2 instance to an Amazon RDS (Relational Database Service) instance. This step aimed to address the limitation of having the database and web server sharing the same instance, which hindered scalability and resilience.

The migration process involved several key steps. Firstly, we created a subnet group to house the RDS instance, ensuring it was launched into a suitable network environment. Next, we created an Amazon RDS instance with the necessary configurations, ensuring to input the same database parameters from the parameter store.

To migrate the WordPress data from the locally hosted MariaDB to the RDS instance, we followed a series of actions. Initially, we connected to the instance and populated the database environmental variables with the values stored in the SSM parameter store. This ensured a smooth transition of data.

Then, we took a backup of the local database data by performing a MySQL dump. Before restoring the backup to the RDS instance, we updated the DB endpoint from "localhost" to the new RDS endpoint. This involved updating the corresponding value in the SSM parameter store and modifying the Instance DB variable to reflect the updated store value.

Next, we restored the local backup by connecting to the new RDS endpoint. Finally, we updated the WordPress configuration files to point to the RDS instance instead of the local MariaDB.

To confirm the success of the migration, we stopped the local MariaDB service running on the instance and tested the WordPress website through the public IP. We verified that all data, including posts and configurations, remained intact, proving the seamless transition to the RDS instance.

By migrating the database to Amazon RDS, we eliminated the limitation of sharing the same instance for the database and web server. This provided us with more flexibility for scaling and improved the overall architecture's reliability and performance.

Join us in the next stage as we further enhance the WordPress architecture, exploring strategies for scaling and implementing failover mechanisms to achieve a highly resilient and scalable system.

## Stage 5: Implementing Highly Available File Storage with Amazon EFS

In the fifth stage of our WordPress architecture evolution, we focused on isolating the file-based data, specifically images, from the WordPress server instance. We achieved this by leveraging Amazon Elastic File System (EFS), a highly available central file share accessible to all instances.

To begin, we created the file system on the EFS console, configuring the appropriate mount points to be deployed in each availability zone where the WordPress instance subnets resided. We ensured the generated file system ID was stored securely in the parameter store for easy retrieval.

Next, we connected the file system (EFS) to the WordPress instance. This involved installing the necessary packages to enable the implementation of EFS mounting. We added the EFS ID, retrieved from the parameter store, to the instance. Subsequently, we mounted the EFS and proceeded to move the data from the instance into the newly mounted file system directory. Appropriate permissions were then set, ensuring proper access to the files. Finally, we rebooted the instance and conducted thorough testing.

During testing, we confirmed that the WordPress site successfully loaded the images, which were now served from the EFS. This demonstrated the successful implementation of highly available file storage, eliminating the risk of image deletion in case of web server failures.

To streamline the process further, we updated the launch template to automate the EFS mount. This was accomplished by modifying the user data with the manual commands we had previously used. This enhancement prepared us for the creation of a comprehensive launch template that could spin up instances with all components in place, including scalable web servers, a database, and the file system.

By isolating file-based data to Amazon EFS, we eliminated the limitation of images being stored inside the instance storage, minimizing the risk of data loss during web server failures.

Join us in the next stage as we continue to refine our architecture, exploring mechanisms for scalability, load balancing, and implementing automated backups to ensure data resilience and high availability.

## Stage 6: Implementing Autoscaling and Load Balancing

In the final stage of our WordPress architecture evolution, we focused on increasing the resiliency and availability of the application by implementing an autoscaling group (ASG) and a load balancer. This step aimed to address the limitations of security risks from direct instance access and lack of self-healing capabilities.

To begin, we created the load balancer, ensuring a target group consisting of the instances that would be launched in the autoscaling group. We noted the load balancer's DNS name and included it in the parameter store, which would be utilized in the launch template's user-data configuration. Additional configurations were made to update variables, directing them to the new Application Load Balancer (ALB) DNS hostname instead of pointing directly to instances in the public subnet.

Next, we created the autoscaling group using the latest version of the gradually evolved launch template. During the creation of the autoscaling group, we attached the existing load balancer and enabled health checks and metrics collection within CloudWatch. These steps were crucial for effective monitoring of the EC2 instances within the ASG.

In the group details of the ASG, we set the minimum, desired, and maximum capacity to one instance each, following the default settings. Upon creating the ASG, a new instance was immediately spun up, compensating for the termination of the previous instance. This behavior was due to the minimum capacity of the ASG being set to one, ensuring the continuous operation of at least one EC2 instance.

We thoroughly tested the WordPress site and confirmed that it continued to function as expected. With the public-facing Application Load Balancer in place, the web server content was served to the public, mitigating the security risk associated with direct instance access.

In the next step, we implemented automatic scaling on the ASG. Two different simple scaling policies were implemented, utilizing the average CPU utilization metric from CloudWatch. A threshold of 40% was set, instructing the ASG to add one capacity unit when the CPU utilization average exceeded 40% and remove one capacity unit when it fell below 40%. We adjusted the group details of the ASG, setting the maximum to three instances, desired to one instance, and the minimum to one instance.

To test the new scaling settings, we simulated stress on the running instance and closely monitored the CPU utilization spike and the ASG console activities. Within a few minutes, we observed the provisioning of a new instance triggered by the increase in CPU utilization metric above 40%. The addition of a second instance was evident in the running instances console, indicating the optimal functioning of the ASG, which responded to the scaling policies, health checks, and metrics.

By implementing autoscaling and load balancing, we successfully resolved the lingering limitations related to security risks from direct instance access and added self-healing capabilities. The load balancer ensured a secure entry point for external users browsing the WordPress site, while the autoscaling group facilitated automatic healing and recovery of instances that failed health checks.

## Conclusion

With a resilient and scalable WordPress architecture in place, we have accomplished the evolution of our system, providing increased availability, improved performance, and enhanced security. The journey from a manually built single instance to a highly resilient and scalable setup demonstrates the power of AWS services and architectural best practices.

Thank you for joining us on this blog series, and we hope it inspires you to explore and implement similar improvements in your own AWS projects.
