#!/bin/bash
# This script is used to set the user data for the react instance

# Retrieve parameter values from SSM
RDS_ENDPOINT=$(aws ssm get-parameter --name "/react-app/db-host" --query "Parameter.Value" --output text)
RDS_DBNAME=$(aws ssm get-parameter --name "/react-app/db-name" --query "Parameter.Value" --output text)
RDS_USERNAME=$(aws ssm get-parameter --name "/react-app/db-username" --query "Parameter.Value" --output text)
RDS_PASSWORD=$(aws ssm get-parameter --name "/react-app/db-password" --with-decryption --query "Parameter.Value" --output text)
GITHUB_TOKEN=$(aws ssm get-parameter --name "/github-token" --with-decryption --query "Parameter.Value" --output text)
INSTANCE_ID=$(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` \
&& curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id)

# Install docker and docker-compose and git
yum update -y
yum install -y docker
yum install -y git
service docker start
usermod -a -G docker ec2-user
chkconfig docker on
curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# pull git repo for react instance
git clone https://mcfwesh:${GITHUB_TOKEN}@github.com/mcfwesh/test-react-express-app-for-aws.git /home/ec2-user/react-app

# Write parameter values to an env file
cat > /home/ec2-user/react-app/server/.env <<EOF
 RDS_ENDPOINT=${RDS_ENDPOINT}
 RDS_DBNAME=${RDS_DBNAME}
 RDS_USERNAME=${RDS_USERNAME}
 RDS_PASSWORD=${RDS_PASSWORD}
 REACT_APP_INSTANCE_ID=${INSTANCE_ID}
 GITHUB_TOKEN=${GITHUB_TOKEN}
EOF

# build docker image
chown ec2-user:ec2-user /home/ec2-user/react-app/docker-compose.yaml
/usr/local/bin/docker-compose -f /home/ec2-user/react-app/docker-compose.yaml up -d --build


