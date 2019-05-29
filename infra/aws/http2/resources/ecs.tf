resource "aws_ecs_cluster" "latency-research-http2" {
  name = "latency-research-http2"
}

resource "aws_ecs_task_definition" "latency-research-http2" {
  family                = "latency-research-http2-service"

  container_definitions = <<DEFS
  [{
    "name": "websv",
    "image": "${aws_ecr_repository.latency-research-http2.repository_url}:latest",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "memory": 1536,
    "cpu": 768,
    "command": ["node", "index.js"]
  }]
DEFS

  network_mode = "host"

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }
}

resource "aws_ecs_service" "latency-research-http2" {
  name            = "latency-research-http2"
  launch_type     = "EC2"
  cluster         = "${aws_ecs_cluster.latency-research-http2.id}"
  task_definition = "${aws_ecs_task_definition.latency-research-http2.arn}"
  iam_role        = "${aws_iam_role.latency-research-http2-ecs-service.arn}"

  scheduling_strategy = "DAEMON"
  // for "REPLICA" storategy. desired_count   = 1

  load_balancer {
    target_group_arn = "${aws_lb_target_group.latency-research-http2.arn}"
    container_name   = "websv"
    container_port   = 80
  }

  /* for "REPLICA" storategy.
  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [ap-northeast-1a, ap-northeast-1c]"
  } */
}

/* resource "aws_appautoscaling_target" "latency-research-http2" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.latency-research-http2.name}/${aws_ecs_service.latency-research-http2.name}"
  role_arn           = "${aws_iam_role.latency-research-http2-auto-scaling.arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "latency-research-http2" {
  name               = "latency-research-http2"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "${aws_appautoscaling_target.latency-research-http2.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.latency-research-http2.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.latency-research-http2.service_namespace}"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80.0
  }
} */
