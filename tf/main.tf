# --------------------------------
# Providers
# --------------------------------

terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
  profile = "terraform"
}

# --------------------------------
# ECR
# --------------------------------

module "ecr" {
  source = "./modules/ecr"
}

# --------------------------------
# ECS
# --------------------------------

module "ecs" {
  source = "./modules/ecs"
  # needed by task defenition resource to reference desired repository
  ecr_repo_url = module.ecr.repository_url 
}

# Export alb_dns_name to tfstate so health_check.sh can use alb endpoint
output "alb_dns_name" {
  value = module.ecs.alb_dns_name
}
