locals {
  ecs_cluster_name = "${var.environment}-ecs-cluster"
  ecs_service_name = "${var.environment}-image-api"
  vpc_name         = "${var.environment}-vpc"
}
