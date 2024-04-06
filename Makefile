# Variables
ACCOUNT_ID = 637423461657
REGION = ap-southeast-2
REPOSITORY = ssc-test-repo
IMAGE_TAG = latest
ECR_IMAGE_URI=${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPOSITORY}:${IMAGE_TAG}

vars:
	@echo "Account ID: $(ACCOUNT_ID)"
	@echo "Region: $(REGION)"
	@echo "Repository: $(REPOSITORY)"

# Create AWS ECR instance
create_ecr:
	cd tf && terraform init && terraform validate && terraform plan -target=module.ecr && terraform apply -auto-approve

# Destroy AWS ECR instance
destroy_ecr:
	cd tf && terraform destroy -target=module.ecr -auto-approve

# Create AWS ECS instance
create_ecs:
	cd tf && terraform init && terraform validate && terraform plan -target=module.ecs && terraform apply -auto-approve
	./health_check.sh

# Destroy AWS ECS instance
destroy_ecs:
	cd tf && terraform destroy -target=module.ecs -auto-approve

# Build docker image
build_docker: vars
	cd app && docker build -t ${REPOSITORY} .

# Push built docker image to ECR
docker_ecr_push: vars
	cd app && aws ecr get-login-password --region ${REGION} --profile terraform | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com
	docker tag ${REPOSITORY}:${IMAGE_TAG} ${ECR_IMAGE_URI}
	docker push ${ECR_IMAGE_URI}