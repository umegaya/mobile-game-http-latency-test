resource "aws_ecs_cluster" "aws-module-ecs-cluster" {
  name = "${var.namespace}"
}

resource "aws_ecs_task_definition" "aws-module-ecs-task-definition" {
  family                = "${var.namespace}-service"

  container_definitions = "${var.container_definitions}"

  network_mode = "host"
}

resource "aws_iam_role" "aws-module-ecs-service-role" {
  name = "${var.namespace}-ecsServiceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aws-module-ecs-service-role-policy-attachement" {
  role = "${aws_iam_role.aws-module-ecs-service-role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "aws-module-ecs-service-role-policy-attachement-elb" {
  role = "${aws_iam_role.aws-module-ecs-service-role.id}"
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

resource "aws_ecs_service" "aws-module-ecs-service" {
  name            = "${var.namespace}"
  launch_type     = "${var.ecs_launch_type}"
  cluster         = "${aws_ecs_cluster.aws-module-ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.aws-module-ecs-task-definition.arn}"
  iam_role        = "${aws_iam_role.aws-module-ecs-service-role.arn}"

  scheduling_strategy = "DAEMON"
  // for "REPLICA" storategy. desired_count   = 1

  load_balancer {
    target_group_arn = "${var.lb_target_group_arn}"
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