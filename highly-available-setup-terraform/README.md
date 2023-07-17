# Highly Available Architecture on AWS using Terraform

## Table of Contents

- [Introduction](#introduction)
- [Web app to be deployed](#web-app-to-be-deployed)
- [Prepare Terraform Environment](#prepare-terraform-environment)
- [Provisioning Resources: VPC, Subnets, Internet Gateway, and Route Table](#provisioning-resources-vpc-subnets-internet-gateway-and-route-table)
- [Provisioning Security Groups: Separation of Concerns](#provisioning-security-groups-separation-of-concerns)
- [Provisioning the PostgreSQL RDS Instance](#provisioning-the-postgresql-rds-instance)
- [Provisioning Instance Roles and Instance Profiles](#provisioning-instance-roles-and-instance-profiles)
- [Provisioning Data Sources](#provisioning-data-sources)
- [Storing DB Parameters in SSM Parameters](#storing-db-parameters-in-ssm-parameters)
- [Creating a user data file to bootstrap the React EC2 instances in the auto-scaling groupp](#creating-a-user-data-file-to-bootstrap-the-react-ec2-instances-in-the-auto-scaling-group)
  - [Challenges (user data)](#challenges-user-data)
- [Provisioning the Load balancer, Auto-Scaling Group and Launch Configuration](#provioning-the-load-balancer-auto-scaling-group-and-launch-configuration)
  - [Challenges (ASG and load balancer)](#challenges-asg-and-load-balancer)
- [Testing and Observations](#testing-and-observations)
  - [Stress Testing 1](#stress-testing-1))
  - [Stress Testing 2](#stress-testing-2)
- [Conclusion](#conclusion)

## Introduction

In this blog post, I am excited to share my experience designing a highly available architecture using AWS services and Terraform. My goal was to create a robust infrastructure that would provide seamless scalability and fault tolerance. To achieve this, I deployed a custom Virtual Private Cloud (VPC) and utilized a combination of services, including PostgreSQL RDS, an autoscaling group, and a load balancer.

To ensure high availability, I distributed my architecture across three availability zones, each containing three subnets. This approach allowed for redundancy and improved resilience. By leveraging Terraform, I was able to automate the entire deployment process, eliminating the need for manual console manipulation. With a focus on simplicity and efficiency, I aimed to achieve a one-click deployment for my full-stack web application.

The web app itself consisted of a React frontend and an Express backend, both containerized using Docker. By leveraging the power of EC2 instances, I orchestrated the deployment process to automatically bootstrap the containers upon launch. This streamlined approach not only saved time but also provided a consistent and reproducible environment for my application.

Throughout this blog series, I will delve into the details of each component, explaining the design choices, best practices, and lessons learned along the way. Join me as we explore the journey of creating a highly available architecture on AWS, using Terraform to automate the deployment process and ensuring a seamless experience for our users. Let's dive in!

## Web app to be deployed

In this stage, I developed a small full-stack app in React and Express and pushed it to a GitHub repository. This web app serves as a great example to demonstrate the effect of a load balancer when stress is applied to the current instance within the ASG (Auto Scaling Group) hosting the web app.

Having a full-stack app allows me to showcase the load balancer's behavior and the scalability of the application. By utilizing React on the frontend and Express on the backend, I can create a responsive and interactive user interface while efficiently handling server-side requests.

Once I deploy this app using the infrastructure I've set up, the load balancer will automatically distribute incoming traffic among the instances in the autoscaling group. As I stress test the app, I will be able to observe how the load balancer dynamically scales the number of instances up or down based on the defined capacity, health checks, and traffic load.

## Prepare Terraform Environment

To kickstart the process, I began by setting up my development environment in Visual Studio Code (VSCode). In my project directory, I created a file called providers.tf to define the necessary provider configuration. For this project, I chose AWS as the provider to deploy our infrastructure.

Within the providers.tf file, I specified the region as US-east-1, where I wanted the deployments to take place. By explicitly setting the region, I ensured consistency and alignment with my project requirements.

Before proceeding, I made sure to authenticate my identity by generating access keys on the AWS console. These access keys would grant the necessary permissions for Terraform to interact with AWS services securely.

Once I had the access keys in place, I ran the terraform init command. This command initialized the Terraform project, fetching the required plugins and setting up the backend configuration, if applicable. It ensured that I had all the necessary dependencies to proceed with the infrastructure provisioning.

With the initialization complete, I was ready to apply the configuration. Using the terraform apply command, I executed the final setup. This command evaluated the defined resources and made any necessary changes to match the desired state described in my Terraform files.

By following these steps, I successfully established the foundation for my AWS environment, configured the provider, specified the region, and authenticated my identity using access keys. With the setup complete, I was ready to move on to the next stages of designing the highly available architecture.

## Provisioning Resources: VPC, Subnets, Internet Gateway, and Route Table

In this stage, I created a main.tf file to provision essential resources for my AWS infrastructure. Let's go through each resource configuration.

To begin, I defined the creation of a Virtual Private Cloud (VPC) using the aws_vpc resource. I specified a CIDR block of 10.16.0.0/16 and enabled DNS support and hostnames to facilitate network resolution.

Next, I created an Internet Gateway (IGW) using the aws_internet_gateway resource. This allowed the public subnets to connect with the internet.

To enable connectivity between the VPC and the internet, I created a route table using the aws_route_table resource. Additionally, I established a default route in the route table that pointed all traffic (public) to the previously created Internet Gateway.

For subnet configuration, I provisioned a total of nine subnets. However, only six of these subnets were utilized in this project. Three subnets were designated for the PostgreSQL RDS instance, and the remaining three were allocated for the web application.

I created three subnets for the RDS instance: h20up_db_subnet_a, h20up_db_subnet_b, and h20up_db_subnet_c. Each subnet had a distinct CIDR block and was associated with an availability zone.

Additionally, I defined three public subnets: h20up_pub_subnet_a, h20up_pub_subnet_b, and h20up_pub_subnet_c. These subnets had a map_public_ip_on_launch parameter set to true, enabling instances launched within them to have public IP addresses. Each public subnet was associated with an availability zone.

Finally, I associated the previously created public route table with the public subnets using the aws_route_table_association resource. This ensured that the subnets would use the correct route table for routing decisions.

During this stage, I encountered a challenge in understanding the concept of associating route tables from Terraform's perspective. I learned that a route table and a route to be used in the route table are separate resources that must be linked through association. Additionally, a route can be added to a route table inline.

By successfully configuring these resources in my main.tf file, I laid the foundation for my AWS infrastructure, establishing the VPC, subnets, internet gateway, and route table. In the next stage, I will focus on provisioning the remaining components and their interconnections.

## Provisioning Security Groups: Separation of Concerns

In this stage, I focused on creating security groups for the various components of my infrastructure. To maintain separation of concerns, I organized the security group configurations in a separate file called security-groups.tf.

Firstly, I created a security group specifically for the React app instances using the aws_security_group resource. This security group, named "dev_react_app_sg," controlled access to the React instances. I allowed incoming TCP traffic on port 80 (HTTP) for direct access from the internet. Additionally, SSH access on port 22 was enabled for administrative purposes. Outbound traffic was allowed to all destinations.

Next, I created a security group for the database (DB) instances using the aws_security_group resource. This security group, named "dev_db_sg," controlled access to the DB instances. I opened port 5432, the default port for the PostgreSQL RDS instance, only to the security group associated with the React app instances. This restriction ensured that only the React app instances could access the DB instances.

Lastly, I created a security group for the load balancer using the aws_security_group resource. This security group, named "dev_load_balancer_sg," controlled access to the load balancer. I allowed incoming TCP traffic on port 80 (HTTP) from any IP address. This configuration ensured that the load balancer could serve as the default access point for external connections.

By creating these security groups, I enhanced the security posture of my infrastructure. Each component had its own security group with appropriate ingress and egress rules, limiting access to specific ports and authorized entities. This separation of concerns helped to enforce the principle of least privilege and enhanced overall security.

In the next stage, I will focus on provisioning the remaining resources, including the RDS instance, autoscaling group, and load balancer, and establishing the necessary connections between them.

## Provisioning the PostgreSQL RDS Instance

In this stage, I focused on provisioning the PostgreSQL RDS instance along with its associated subnet group. I organized the configuration in a separate file called `db.tf`.

Firstly, I created a subnet group for the RDS instance using the `aws_db_subnet_group` resource. This subnet group, named "h20up_db_subnet_group," included all three subnets previously created. By associating the RDS instance with this subnet group, I ensured that the instance would be deployed across all three subnets.

Next, I provisioned the RDS instance itself using the `aws_db_instance` resource. I chose the PostgreSQL engine and specified the necessary details such as the allocated storage, instance class, storage type, database name, username, and password. I set the `publicly_accessible` attribute to "false" to restrict public access to the RDS instance.

For the availability zone, I selected the first availability zone from the available list using the `element` function. This configuration deployed the RDS instance into a single availability zone for now, without Multi-AZ redundancy.

I specified the subnet group created earlier using the `db_subnet_group_name` attribute, ensuring that the RDS instance was associated with the correct subnets. The security group for the RDS instance was provided using the `vpc_security_group_ids` attribute, referencing the security group created for the DB.

To optimize resource utilization, I set `skip_final_snapshot` to true, indicating that no final snapshot would be taken when the RDS instance is terminated.

By provisioning the PostgreSQL RDS instance and associating it with the appropriate subnet group and security group, I established a scalable and managed database infrastructure for my project. In the next stage, I will focus on provisioning the remaining components, including the autoscaling group and load balancer, to create a highly available architecture.

## Provisioning Instance Roles and Instance Profiles

In this stage, I focused on provisioning instance roles and instance profiles to be used by the EC2 instances. The configuration was organized in a file called roles.tf.

Firstly, I created an IAM role using the aws_iam_role resource. This role, named "h20up_react_instance_role," had a trust policy that allowed EC2 instances to assume the role using the sts:AssumeRole action. The Service parameter in the trust policy specified that the EC2 service was trusted. Additionally, the role was associated with the AmazonSSMManagedInstanceCore managed policy, which granted permissions for interacting with the SSM Parameter service. This permission was necessary for retrieving DB parameters from the SSM parameters when provisioning the auto-scaling group.

Next, I provisioned an instance profile using the aws_iam_instance_profile resource. The instance profile, named "h20up_react_instance_profile," served as a container for the previously created instance role. I associated the role with the instance profile using the role attribute.

By creating the instance role and instance profile, I established the necessary permissions for the EC2 instances to interact with the SSM Parameter service and ensured secure access to resources.

## Provisioning Data Sources

In addition to the instance roles and profiles, I declared data sources in the data_sources.tf file. These data sources provided information that could be used in later resource provisioning.

The first data source, aws_ami, retrieved the AMI (Amazon Machine Image) to be used later. It filtered the AMIs based on the specified owner and name. The AMI ID would be available in the data.aws_ami.ami_server.id attribute and could be referenced when provisioning EC2 instances.

The second data source, aws_availability_zones, automatically sourced the availability zones for the chosen region, us-east-1. This data source provided a list of availability zone names in the data.aws_availability_zones.available.names attribute. This information was used in previous stages and would continue to be used in subsequent resource provisioning.

By using data sources, I could retrieve and utilize information dynamically during the infrastructure provisioning process, ensuring flexibility and ease of management.

In the next stage, I will focus on provisioning the auto-scaling group and launch configuration to create a scalable and resilient environment for the web application.

## Storing DB Parameters in SSM Parameters

In this stage, I provisioned AWS SSM (Systems Manager) Parameter resources to securely store the DB parameters required to connect to the RDS instance. I made sure to set the password as a SecureString, ensuring that it is encrypted and remains protected.

I used the aws_ssm_parameter resource to create SSM parameters for the following DB parameters:

db_host: The host address of the RDS instance.

db_port: The port number used to connect to the RDS instance.

db_name: The name of the database within the RDS instance.

db_username: The username used to authenticate with the RDS instance.

db_password: The password used to authenticate with the RDS instance (stored as a SecureString).

For each parameter, I provided a specific name, type, and value. I used a consistent path pattern of /react-app/parameter-name to organize the parameters related to the React app. The type attribute was set to "String" or "SecureString" based on whether the parameter contained sensitive information or not. The value attribute held the corresponding value of the parameter retrieved from the AWS resources.

By securely storing these DB parameters as SSM parameters, I ensured that sensitive information, such as the database password, is not exposed in plain text. This approach follows security best practices and allows me to easily manage and retrieve these parameters when provisioning the auto-scaling group, which will be helpful in the next stages of the infrastructure setup.

## Creating a user data file to bootstrap the React EC2 instances in the auto-scaling group

In this stage, I created a user data file named react_instance_user_data.tpl, which contains a script that will be executed when the React instance is launched. The user data script performs several tasks to bootstrap the instance and deploy the React web app.

Here's an overview of what the user data script does:

It retrieves the necessary DB parameters from the AWS SSM Parameter Store using the AWS CLI commands aws ssm get-parameter. The script fetches the RDS endpoint, database name, username, and password from the corresponding SSM parameters.

The script obtains the instance ID of the current EC2 instance by making a request to the instance metadata service.

It proceeds to install Docker, Docker Compose, and Git on the instance. This is done by updating the package manager, installing the required packages, starting the Docker service, and granting the ec2-user group permissions to use Docker.

The script clones the Git repository containing the React web app source code from the specified URL (https://github.com/mcfwesh/test-react-express-app-for-aws.git) and stores it in the /home/ec2-user/react-app directory.

It creates an environment file (/home/ec2-user/react-app/server/.env) and populates it with the retrieved DB parameter values, as well as the instance ID.

The script sets appropriate ownership for the docker-compose.yaml file and builds the Docker image by running the docker-compose command with the specified YAML file (/home/ec2-user/react-app/docker-compose.yaml). The web app is launched in detached mode (-d) with the --build flag to rebuild the Docker image if necessary.

By using this user data script, the React instance can be automatically provisioned and configured with the required dependencies, retrieve DB parameters securely from the SSM Parameter Store, clone the React web app from the Git repository, and launch the app using Docker and Docker Compose.

### Challenges (user data)

During the process of creating a suitable file to bootstrap the EC2 instances, I encountered a couple of challenges:

First, properly fetching the SSM parameters and saving them to an environment file was a bit tricky. I needed to use the AWS CLI commands (aws ssm get-parameter) and ensure that I passed the correct parameter names, performed the necessary queries, and handled the responses to extract the desired parameter values. It required some experimentation and troubleshooting to get it right.

Second, running Docker Compose as the root user posed some challenges. By default, Docker Compose commands require certain permissions that may not be available to the root user. This can lead to permission-related issues when building and running the containers. To overcome this, I needed to grant the necessary permissions to the user executing the Docker Compose commands. In my case, I granted the ec2-user group permissions to use Docker, which allowed me to successfully run the Docker Compose command.

By addressing these challenges and implementing the necessary steps in my user data script, I was able to overcome these hurdles and successfully bootstrap the EC2 instances. I ensured that the SSM parameters were fetched correctly and saved to an environment file, and I resolved the permission issues to run Docker Compose as the ec2-user, allowing me to build and run the containers successfully.

## Provisioning the Load balancer, Auto-Scaling Group and Launch Configuration

In the next stage, I created the autoscaling groups (ASG) and load balancers in a separate file called asg-lb.tf. Let me break down the process for you.

Firstly, I created the load balancer, aws_lb, with the name "dev-load-balancer". It was configured as an application load balancer that is externally accessible. Cross-zone load balancing was enabled to achieve high availability. The load balancer was associated with the security group and subnets that were previously defined.

Next, I created the load balancer target group, aws_lb_target_group, named "dev-target-group". The target group specifies the port, protocol, and health check settings for the instances that will be registered with the load balancer.

Following that, I defined a listener, aws_lb_listener, for the load balancer. The listener configuration specified that incoming traffic on port 80 should be forwarded to the target group we created earlier.

Moving on, I created a key pair, aws_key_pair, that can be used to SSH into the instances. The public key file for the key pair was provided.

Then, I defined a launch template, aws_launch_template, which will be used to provision the EC2 instances in the ASG. The launch template included the image ID, instance type, key pair, user data (the bootstrap script), and the instance profile.

Finally, I created the autoscaling group, aws_autoscaling_group, named "dev_asg". The ASG was configured with a minimum capacity of 1 instance, a desired capacity of 2 instances, and a maximum capacity of 3 instances. The health check type was set to "EC2" to ensure that the instances in the ASG are healthy. The VPC subnets were specified, and the launch template and target group were associated with the ASG. Dependencies were added to ensure that the SSM parameters were fetched before creating the ASG.

By provisioning the ASG and load balancer, I established an infrastructure that can automatically scale the number of instances based on the configured capacity and distribute incoming traffic to the instances using the load balancer.

### Challenges (ASG and load balancer)

Challenges I encountered during this stage included unintentionally skipping the provisioning of listener configurations, resulting in the load balancer not being active. I had to troubleshoot and add the necessary listener configuration to associate the load balancer with the load balancer target group. Additionally, I initially omitted the instance profile in the launch template, causing the EC2 instances to be unable to access the SSM parameters during instance bootstrapping. I resolved this issue by adding the instance profile to the launch template, ensuring proper access to the SSM parameters.

By addressing these challenges and properly configuring the autoscaling groups and load balancers, I successfully provisioned the infrastructure needed for my application

## Testing and Observations

In the next stage of applying the Terraform provisioning, I ran the terraform apply command after carefully reviewing the execution plan. This command deployed the infrastructure components as defined in the Terraform configuration files.

Once the provisioning was complete, I wanted to test the deployed infrastructure and observe the behavior of the load balancer and auto scaling. To do this, I opened a web browser and entered the public IP address of the load balancer. The web page displayed the current instance ID that was hosting the web app.

### Stress Testing 1

To stress test the infrastructure, I SSHed into the instance that was indicated on the web page. Inside the instance, I used the stress package available in the yum package manager to generate a simulated high load on the system. I ran the stress test for 60 seconds to evaluate the performance and scalability of the application.

Returning to the web page, I continuously refreshed it to monitor any changes in the instance ID displayed. After a short period, I noticed that a different instance ID appeared, indicating that the load balancer had switched the request to another running instance. This dynamic behavior demonstrated the load balancer's ability to distribute traffic and seamlessly shift the workload between instances in response to changes in demand.

### Stress Testing 2

Additionally, I performed another stress test by intentionally terminating one of the two instances that were always running in the Auto Scaling Group. After the termination, I observed a cooldown period during which the load balancer detected the instance's unavailability. Once the cooldown period ended, the load balancer automatically directed traffic to the remaining running instance, ensuring uninterrupted service.

These stress tests allowed me to verify the effectiveness of the load balancer and the auto scaling functionality. The infrastructure successfully handled increased load by distributing traffic across multiple instances and adapting to changes in the instance pool.

## Conclusion

In conclusion, using Terraform, I seamlessly provisioned and orchestrated a robust and scalable infrastructure on AWS for hosting my full-stack web application. From setting up the VPC, subnets, security groups, and IAM roles to deploying EC2 instances with user data scripts and configuring load balancers and auto scaling groups, Terraform proved to be an invaluable tool.

With Terraform's declarative approach, I easily defined my desired infrastructure state in code, allowing for version control and easy collaboration with my team. The ability to plan and apply changes, as well as efficiently manage resources using Terraform, brought a level of automation and repeatability that saved me valuable time and reduced the chances of human error.

Notably, the combination of AWS's services with Terraform's simplicity and power enabled me to create a highly available and fault-tolerant system. The load balancer effectively distributed incoming traffic across multiple instances, and the auto scaling group dynamically adjusted the capacity based on demand. During my stress tests, the infrastructure responded flawlessly, demonstrating the seamless switching of instances and the adaptability of the system.
