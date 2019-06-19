resource "aws_ecs_cluster" "aws-module-ecs-cluster" {
  name = "${var.namespace}"
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
