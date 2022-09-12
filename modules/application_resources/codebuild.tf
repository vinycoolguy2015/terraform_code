#data "terraform_remote_state" "service" {
#  backend = "s3"
#  depends_on = [aws_ecs_service.ecs_service]
#  config = {
#    bucket = var.bucket
#    key    = format("environments/%s/%s/terraform.tfstate", var.environment, "application_resources")
#    region = var.aws_region
#  }
#}
resource "aws_codebuild_project" "ecs_build" {
  badge_enabled  = false
  build_timeout  = var.build_timeout
  name           = "codebuild-${var.environment}-image-api"
  queued_timeout = var.queued_timeout
  service_role   = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:2.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    type                        = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }

    s3_logs {
      encryption_disabled = false
      status              = "DISABLED"
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = data.template_file.buildspec.rendered
  }
}

data "template_file" "buildspec" {
  template = file("buildspec.tpl")
  vars = {
    container_port  = var.docker_container_port
    container_name  = "${var.environment}-image-api-container"
    task_definition = aws_ecs_service.ecs_service.task_definition
  }
}
