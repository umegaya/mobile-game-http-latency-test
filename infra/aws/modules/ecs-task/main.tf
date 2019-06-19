resource "aws_ecs_task_definition" "aws-module-ecs-task-definition" {
  family                = "${var.namespace}-service"

  container_definitions = "${var.container_definitions}"

  network_mode = "${var.task_network_mode}"
}

resource "aws_ecs_service" "aws-module-ecs-task-service" {
  name            = "${var.namespace}-${var.container_name}"
  launch_type     = "${var.ecs_launch_type}"
  cluster         = "${var.ecs_cluster_id}"
  task_definition = "${aws_ecs_task_definition.aws-module-ecs-task-definition.arn}"
  iam_role        = "${var.service_role_arn}"

  scheduling_strategy = "${var.scheduling_strategy}"
  // for "REPLICA" storategy. desired_count   = 1

  load_balancer {
    target_group_arn = "${var.lb_target_group_arn}"
    container_name   = "${var.container_name}"
    container_port   = var.container_forwarded_port
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