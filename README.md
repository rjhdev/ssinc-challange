# ssinc-challange

This project creates a docker image of a golang application. 
Using terraform it also instantiates an ECR and ECS instances to store the image for use in the ECS cluster running on an EC2 instance.
The controller to abstract the commands used to run terraform and other taks will be in the form of a makefile.

## Requirements

As the root user in AWS console create the following AMI credentials. Terraform will use this AWS user to perform actions.

1) IAM Group: terraform (Policy: AdministratorAccess)
2) IAM User: terraform (Group: terraform)

## Deployment

This section outlines the steps required to deploy the application using the provided Makefile and GitHub Actions for continuous integration and continuous deployment (CI/CD). So there are two options here which involve manual makefile method or automatic CI/CD github actions method.

## Makefile Usage

To deploy the application, use the following commands defined in the Makefile. These commands automate the processes of creating infrastructure, building the Docker image, and managing deployments.

### Set Variables

Run **make vars** to set and verify the environment variables required for deployment. Make sure these are correct for your setup.

### Create AWS ECR Instance

Use **make create_ecr** to provision an Elastic Container Registry (ECR) instance where the Docker image will be stored.

### Create AWS ECS Instance

Execute **make create_ecs** to create an Elastic Container Service (ECS) instance for running the application on EC2 instances.

### Build Docker Image

**make build_docker** builds the Docker image of the application if you prefer to do this without github actions. Otherwise code changes to the application in **app** will be automatically built and pushed to ECR through github.

### Push Docker Image to ECR

With **make docker_ecr_push**, the built Docker image is tagged and pushed to the ECR repository for deployment if your prefer to do t his without github actions.

### Destroy AWS ECR Instance

To remove the ECR instance, use **make destroy_ecr**.

### Destroy AWS ECS Instance

**make destroy_ecs** removes the ECS instance and associated resources.

## GitHub Actions for CI/CD

The .github/workflows/deploy.yml file automates the deployment with GitHub Actions. This CI/CD pipeline triggers on commits to the repository, automating the building of the Docker image and its deployment to AWS ECS.

* AWS_ACCESS_KEY_ID
* AWS_SECRET_ACCESS_KEY

### Important Notes

Make sure **Repository secrets** in the Actions secrets and variables section of the Actions section contains these keys and their correct IDs for the action to complete successfullly.

