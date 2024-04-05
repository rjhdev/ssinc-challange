# ---------------------------
# ECR 

resource "aws_ecr_repository" "ssc" {
  name = "ssc-test-repo"

  # basic image scan health check
  image_scanning_configuration {
    scan_on_push = true
  }
}

# repository URL needed by ECS module so export it
output "repository_url" {
  value = aws_ecr_repository.ssc.repository_url
}
