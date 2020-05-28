resource "aws_cloudwatch_log_group" "log_group" {
  name = var.app_name
}

resource "aws_ecr_repository" "repo_app" {
  name = "repo_${var.app_name}_${var.environment}"
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.app_name}-${var.environment}-EcsCluster"
}

data "template_file" "template_task" {
  template = file("${path.module}/templates/task_definition.json")

  vars = {
    app_name        = "${var.app_name}-${var.environment}"
    image           = aws_ecr_repository.repo_app.repository_url
    log_group       = aws_cloudwatch_log_group.log_group.name
    region          = var.region
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "${var.app_name}_${var.environment}_task"
  container_definitions    = data.template_file.template_task.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_execution_role.arn
}

resource "random_id" "uuid_target_group" {
  byte_length = 2
}

resource "aws_alb_target_group" "alb_target_group" {
  name     = "${var.environment}-alb-target-group-${random_id.uuid_target_group.hex}"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "inbound_sg" {
  name        = "${var.app_name}-${var.environment}-inbound-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-inbound-sg"
  }
}

resource "aws_alb" "alb" {
  name            = "${var.app_name}-alb-${var.environment}"
  subnets         = var.public_subnet_ids
  security_groups = [aws_security_group.inbound_sg.id]

  tags = {
    Name        = "${var.app_name}-alb-${var.environment}"
  }
}

resource "aws_alb_listener" "listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "8000"
  protocol          = "HTTP"
  depends_on        = [aws_alb_target_group.alb_target_group]

  default_action {
    target_group_arn = aws_alb_target_group.alb_target_group.arn
    type             = "forward"
  }
}

data "aws_iam_policy_document" "ecs_service_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_role" {
  name               = "ecs_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_service_role.json
}

data "aws_iam_policy_document" "ecs_service_policy" {
  statement {
    effect = "Allow"
    resources = ["*"]
    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress"
    ]
  }
}

resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "ecs_service_role_policy"
  policy = data.aws_iam_policy_document.ecs_service_policy.json
  role   = aws_iam_role.ecs_role.id
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = file("${path.module}/templates/ecs-task-execution-role.json")
}
resource "aws_iam_role_policy" "ecs_execution_role_policy" {
  name   = "ecs_execution_role_policy"
  policy = file("${path.module}/templates/ecs-execution-role-policy.json")
  role   = aws_iam_role.ecs_execution_role.id
}

resource "aws_security_group" "ecs_service_sg" {
  vpc_id      = var.vpc_id
  name        = "${var.environment}-ecs-service-sg"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ecs-service-sg"
  }
}

data "aws_ecs_task_definition" "data_td" {
  task_definition = aws_ecs_task_definition.task_definition.family
  depends_on = [aws_ecs_task_definition.task_definition]
}

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.app_name}-${var.environment}"
  task_definition = "${aws_ecs_task_definition.task_definition.family}:${max("${aws_ecs_task_definition.task_definition.revision}", "${data.aws_ecs_task_definition.data_td.revision}")}"
  desired_count   = 2
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.cluster.id

  network_configuration {
    security_groups = concat(var.security_groups_ids, aws_security_group.ecs_service_sg.*.id)
    subnets         = var.subnets_ids
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.alb_target_group.arn
    container_name   = "${var.app_name}-${var.environment}"
    container_port   = "8000"
  }

  depends_on = [aws_alb_target_group.alb_target_group, aws_iam_role_policy.ecs_service_role_policy]
}

resource "aws_iam_role" "ecs_autoscale_role" {
  name               = "${var.environment}_ecs_autoscale_role"
  assume_role_policy = file("${path.module}/templates/ecs-autoscale-role.json")
}
resource "aws_iam_role_policy" "ecs_autoscale_role_policy" {
  name   = "ecs_autoscale_role_policy"
  policy = file("${path.module}/templates/ecs-autoscale-role-policy.json")
  role   = aws_iam_role.ecs_autoscale_role.id
}

resource "aws_appautoscaling_target" "target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = aws_iam_role.ecs_autoscale_role.arn
  min_capacity       = 1
  max_capacity       = 3
}

resource "aws_appautoscaling_policy" "up" {
  name                    = "${var.environment}_scale_up"
  service_namespace       = "ecs"
  resource_id             = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension      = "ecs:service:DesiredCount"


  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment = 1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

resource "aws_appautoscaling_policy" "down" {
  name                    = "${var.environment}_scale_down"
  service_namespace       = "ecs"
  resource_id             = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension      = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment = -1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = "${var.app_name}_${var.environment}_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "85"

  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.ecs_service.name
  }

  alarm_actions = [aws_appautoscaling_policy.up.arn]
  ok_actions    = [aws_appautoscaling_policy.down.arn]
}