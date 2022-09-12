
resource "aws_codedeploy_app" "default" {
  compute_platform = "ECS"
  name             = "${var.environment}-codedeploy"
}

resource "aws_codedeploy_deployment_group" "default" {
  app_name               = aws_codedeploy_app.default.name
  deployment_group_name  = "${var.environment}-codedeployment-group"
  service_role_arn       = aws_iam_role.iam-rle-ecs-codedeploy.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    =  "CONTINUE_DEPLOYMENT" 
    }

    # You can configure how instances in the original environment are terminated when a blue/green deployment is successful.
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = (var.environment == "test") ? 0 : 10
    }
  }

  # For ECS deployment, the deployment type must be BLUE_GREEN, and deployment option must be WITH_TRAFFIC_CONTROL.
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  # Configuration block(s) of the ECS services for a deployment group.
  ecs_service {
    cluster_name = local.ecs_cluster_name
    service_name = local.ecs_service_name
  }

  # You can configure the Load Balancer to use in a deployment.
  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_alb_listener.ecs_alb_http_listener.arn]
      }
      test_traffic_route {
        listener_arns = [aws_alb_listener.ecs_alb_test_listener.arn]
      }

      target_group {
        name = aws_alb_target_group.ecs_default_target_group.name
      }

      target_group {
        name = aws_alb_target_group.ecs_test_target_group.name
      }
    }
  }
}
