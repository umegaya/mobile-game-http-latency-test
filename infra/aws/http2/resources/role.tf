resource "aws_iam_role" "latency-research-http2" {
  name = "ecsInstanceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "latency-research-http2" {
  name = "ecsInstanceRole"
  role = "${aws_iam_role.latency-research-http2.name}"
}

resource "aws_iam_role" "latency-research-http2-ecs-service" {
  name = "ecsServiceRole"

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

resource "aws_iam_role" "latency-research-http2-auto-scaling" {
  name = "ecsAutoscaleRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "application-autoscaling.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "latency-research-http2" {
  role = "${aws_iam_role.latency-research-http2.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "latency-research-http2-ecs-service" {
  role = "${aws_iam_role.latency-research-http2-ecs-service.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "latency-research-http2-ecs-service-elb" {
  role = "${aws_iam_role.latency-research-http2-ecs-service.id}"
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

resource "aws_iam_role_policy_attachment" "latency-research-http2-auto-scaling" {
  role = "${aws_iam_role.latency-research-http2-auto-scaling.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}
