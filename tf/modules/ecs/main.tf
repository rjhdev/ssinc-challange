# ---------------------------
# Cluster
# ---------------------------

resource "aws_ecs_cluster" "ssc_cluster" {
  name = "ssc-test-cluster"
}

# ---------------------------
# VPC + subnets
# ---------------------------

# Using two available zones in Sydney and default subnet.

resource "aws_default_vpc" "default_vpc" { }

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "ap-southeast-2a"
}
resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "ap-southeast-2b"
}

# ---------------------------
# ECS Task
# ---------------------------

# Input Variables from parent main.tf
variable "ecr_repo_url" {
  description = "URL of the ECR repository"
  type        = string
}

resource "aws_ecs_task_definition" "ssc_task" {
    family                = "ssc-app-task"
    container_definitions = jsonencode([
    {
      name      = "ssc-app-task"
      image     = "${var.ecr_repo_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        },
      ]
      # FIXME: ROB: ECS task definition health Check, disabled, 
      #        tasks were going into unhealthy state?
      # ECS Task Health Check
      #   healthCheck = {
      #   retries = 3,
      #   command = ["CMD-SHELL", "curl -f http://localhost/health || exit 1"],
      #   timeout = 5,
      #   interval = 30,
      #   startPeriod = 60
      # },
  }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
}

# ---------------------------
# IAM Policy
# ---------------------------

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------------------------
# ALB Load Balancer
# ---------------------------

resource "aws_alb" "application_load_balancer" {
  name               = "ssc-loadbalancer"
  load_balancer_type = "application"
  subnets = [
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}"
  ]
  security_groups = ["${aws_security_group.ssc_secgrp.id}"]
}

resource "aws_lb_target_group" "target_group" {
  name        = "ccs-app-alb"
  port        = 80 # container port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id
  health_check {
    enabled             = true
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# Export alb dns name so when can query it from a monitoring script
output "alb_dns_name" {
  value = aws_alb.application_load_balancer.dns_name
}

# ---------------------------
# Security Group
# ---------------------------

resource "aws_security_group" "ssc_secgrp" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "service_security_group" {
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.ssc_secgrp.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# ECS Service
# ---------------------------

resource "aws_ecs_service" "demo_app_service" {
  name            = "ssc-service"
  cluster         = aws_ecs_cluster.ssc_cluster.id
  task_definition = aws_ecs_task_definition.ssc_task.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = aws_ecs_task_definition.ssc_task.family
    container_port   = 80
  }

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}"]
    assign_public_ip = true
    security_groups  = ["${aws_security_group.ssc_secgrp.id}"]
  }
}
