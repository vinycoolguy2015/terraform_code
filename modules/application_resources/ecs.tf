
resource "aws_cloudwatch_log_group" "log_group" {
  name = "${local.ecs_service_name}-LogGroup"
}

resource "aws_ecs_cluster" "fargate-cluster" {
  name = local.ecs_cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

data "template_file" "ecs_task_definition_template" {
  template = file("${path.module}/task_definition.json")
  vars = {
    task_definition_name  = "${local.ecs_service_name}-container"
    ecs_service_name      = local.ecs_service_name
    docker_image_url      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/ecr-${var.environment}"
    memory                = var.memory
    docker_container_port = var.docker_container_port
    region                = var.aws_region
  }
}

resource "aws_ecs_task_definition" "ecs-task-definition" {
  container_definitions    = data.template_file.ecs_task_definition_template.rendered
  family                   = local.ecs_service_name
  cpu                      = var.cpu
  memory                   = var.memory
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_cluster_ecstaskrole.arn
  task_role_arn            = aws_iam_role.ecs_cluster_ecstaskrole.arn
}


resource "aws_ecs_service" "ecs_service" {
  name            = local.ecs_service_name
  task_definition = aws_ecs_task_definition.ecs-task-definition.arn
  desired_count   = var.desired_task_number
  cluster         = aws_ecs_cluster.fargate-cluster.id
  launch_type     = "FARGATE"
  deployment_controller {
    type = "CODE_DEPLOY"
  }
  network_configuration {
    subnets          = aws_subnet.private_subnet.*.id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    container_name   = "${local.ecs_service_name}-container"
    container_port   = var.docker_container_port
    target_group_arn = aws_alb_target_group.ecs_default_target_group.arn
  }
  lifecycle {
    ignore_changes = [
      load_balancer,
      desired_count,
      task_definition
    ]
  }
}

