# Multi Stage Application Deployment Pipeline 
1. App defined: Simple Python Webpage using Flask
2. Dockerized App Image
3. Terraform builds infrastructure including VPC, Security Group, and EC2 Instance in AWS
4. Ansible runs a playbook to install docker on the EC2 Instance, pull the apps image from Docker Hub, and runs the container.
5. Pull secrets from a Vault rather than hardcoding values
6. GitHub Actions Pipeline will define the CI/CD jobs build, deploy-dev, deploy-stg, and deploy-prd
