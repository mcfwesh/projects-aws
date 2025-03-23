# Database Migration from On-Premises to AWS using DMS

## Table of Contents

- [Introduction](#introduction)
- [Stage 1: CloudFormation Stack Deployment](#stage-1-cloudformation-stack-deployment)
- [Stage 2: VPC Peering and Route Configuration](#stage-2-vpc-peering-and-route-configuration)
- [Stage 3: Web Server Migration to AWS](#stage-3-web-server-migration-to-aws)
- [Stage 4: Database Migration to AWS](#stage-4-database-migration-to-aws)
- [Conclusion](#conclusion)

## Introduction

I migrated a MariaDB database from a simulated on-premises environment to AWS using AWS Database Migration Service (DMS). The goal was to move a web app (WordPress) from on-prem to an EC2 webserver and an RDS MariaDB instance in AWS. DMS provides a streamlined way to handle this.

## Stage 1: CloudFormation Stack Deployment

I started by deploying a CloudFormation stack. This created the AWS environment _and_ a simulated on-premises environment within AWS. Key resources included:

- **VPC:** The networking foundation. This included subnets, security groups, and internet gateways.
- **EC2 Instances:** One for the on-premises database and one for the on-premises web application.
- **IAM Roles:** Defined permissions for the instances.
- **Database Secrets:** Stored securely for later use.

This setup gave me the basic infrastructure for the migration.

## Stage 2: VPC Peering and Route Configuration

This stage focused on connecting the simulated on-premises VPC and the AWS VPC. I used VPC peering and configured route tables:

1.  **VPC Peering:** Created a connection between the two VPCs, allowing them to communicate using private IPs.
2.  **Route Table Configuration:**
    - **AWS VPC:** Routed traffic destined for the on-premises public IP through the VPC peering connection.
    - **On-Premises VPC:** Routed traffic destined for the AWS public IP through the VPC peering connection.

This created a secure network path between the two environments.

## Stage 3: Web Server Migration to AWS

I migrated the web server (running WordPress) to an EC2 instance ("awsCatWeb") in AWS:

1.  **Launch EC2 Instance:** Launched "awsCatWeb" in the correct subnet and availability zone (defined in the CloudFormation stack).
2.  **Install Software:** Installed Apache and MariaDB SQL tools:
    ```bash
    yum -y install httpd mariadb
    amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
    ```
    Then, I restarted the instance.
3.  **Configure Database Authentication (Temporary):**
    - Because the database was _still_ on-premises at this point, I _temporarily_ enabled password authentication in `/etc/ssh/sshd_config` (changed `PasswordAuthentication no` to `PasswordAuthentication yes`).
    - Set a password for `ec2-user` using `passwd ec2-user`, using the DB password from the CloudFormation parameters (matching the on-premises DB password).
    - Restarted the server. _Important:_ This is not a production-ready security practice, but was necessary for this specific migration step.
4.  **Copy Files:** Used SCP to copy files from the on-premises web server to the AWS web server (using its private IP).
5.  **Verify and Set Permissions:** Verified the files were copied and set the correct permissions for the webroot.
6.  **Confirm Migration:** Accessed the AWS web server's public IP in a browser. The WordPress site should load, confirming the web server migration.

## Stage 4: Database Migration using AWS Database Migration Service (DMS)

Finally, I migrated the database itself using DMS:

1.  **Create RDS MariaDB Instance:**
    - Created subnet groups for the RDS instance.
    - Provisioned the RDS MariaDB instance with appropriate settings.
2.  **Set up DMS Replication Instance and Endpoints:**
    - Created a DMS replication instance (an EC2 instance that handles the replication).
    - Created two endpoints:
      - **Source DB Endpoint:** For the on-premises database.
      - **Target DB Endpoint:** For the AWS RDS instance.
    - Tested the endpoints to ensure connectivity.
3.  **Configure and Run Replication Task:**
    - Created a DMS replication task, specifying:
      - Source and target endpoints.
      - Tables/schemas to migrate.
      - Any necessary transformations.
    - Ran the task to start the replication.
4.  **Update Web Server Configuration:**
    - SSHed into the AWS web server.
    - Updated the database hostname in the web server's configuration to point to the new RDS instance.
    - Updated the WordPress database configuration to use the RDS instance hostname.
5.  **Test:**
    - Stopped the on-premises infrastructure (web server and database).
    - Accessed the AWS web server's public IP. The site should load, pulling data from the RDS instance.

## Conclusion

I successfully migrated a WordPress application and its MariaDB database from a simulated on-premises environment to AWS using VPC peering and DMS. This involved migrating the web server to an EC2 instance and the database to an RDS instance, with DMS handling the data replication. The final result is a fully functional application running entirely within AWS.
