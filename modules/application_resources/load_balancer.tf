
resource "aws_alb" "ecs_cluster_alb" {
  name            = "${local.ecs_cluster_name}-ALB"
  internal        = false
  security_groups = [aws_security_group.alb_sg.id]
  subnets         = aws_subnet.public_subnet.*.id
  tags = {
    Name = "${local.ecs_cluster_name}-ALB"
  }
}

resource "aws_alb_listener" "ecs_alb_http_listener" {
  load_balancer_arn = aws_alb.ecs_cluster_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_default_target_group.arn
  }
  depends_on = [aws_alb_target_group.ecs_default_target_group]
}

resource "aws_alb_listener" "ecs_alb_test_listener" {
  load_balancer_arn = aws_alb.ecs_cluster_alb.arn
  port              = 8080
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_test_target_group.arn
  }
  depends_on = [aws_alb_target_group.ecs_test_target_group]
}

resource "aws_alb_target_group" "ecs_default_target_group" {
  name        = "${local.ecs_cluster_name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "404"
    interval            = "10"
    timeout             = "5"
    unhealthy_threshold = "3"
    healthy_threshold   = "3"
  }
  tags = {
    Name = "${local.ecs_cluster_name}-tg"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_target_group" "ecs_test_target_group" {
  name        = "${local.ecs_cluster_name}-testtg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "404"
    interval            = "10"
    timeout             = "5"
    unhealthy_threshold = "3"
    healthy_threshold   = "3"
  }
  tags = {
    Name = "${local.ecs_cluster_name}-testtg"
  }
  lifecycle {
    create_before_destroy = true
  }
}
