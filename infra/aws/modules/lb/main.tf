resource "aws_security_group" "aws-module-lb-security-group" {
  count       = "${var.lb_type == "application" ? 1 : 0}"
  name        = "${var.namespace}-lb"
  description = "Allow necessary inbound traffic for latency research http2 lb"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group_rule" "aws-module-lb-security-group-rule" {
  count           = "${var.lb_type == "application" ? length(var.served_ports) : 0}"
  type            = "ingress"
  from_port       = "${var.served_ports[count.index]}"
  to_port         = "${var.served_ports[count.index]}"
  cidr_blocks     = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  protocol        = "tcp"

  security_group_id = "${aws_security_group.aws-module-lb-security-group[0].id}"
}

data "aws_elb_service_account" "main" {}

locals {
  a_policy = <<A_POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.namespace}-lb-logs/*",
      "Principal": {
        "AWS": [
          "${data.aws_elb_service_account.main.arn}"
        ]
      }
    }
  ]
}
A_POLICY

  n_policy = <<N_POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSLogDeliveryWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": [ "delivery.logs.amazonaws.com" ]
      },
      "Action": [ "s3:PutObject" ],
      "Resource": "arn:aws:s3:::${var.namespace}-lb-logs/*",
      "Condition": {"StringEquals": {"s3:x-amz-acl": "bucket-owner-full-control"}}
    },
    {
      "Sid": "AWSLogDeliveryAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": [ "delivery.logs.amazonaws.com" ]
      },
      "Action": [ "s3:GetBucketAcl" ],
      "Resource": "arn:aws:s3:::${var.namespace}-lb-logs"
    }
  ]
}
N_POLICY
}


resource "aws_s3_bucket" "aws-module-lb-s3-bucket-logs" {
  bucket = "${var.namespace}-lb-logs"
  acl    = "private"

  policy = "${var.lb_type == "application" ? local.a_policy : local.n_policy}"
}

resource "aws_lb" "aws-module-lb-lb" {
  name               = "${var.namespace}-lb"
  internal           = false
  load_balancer_type = "${var.lb_type}"
  security_groups    = [for sg in aws_security_group.aws-module-lb-security-group: sg.id]
  subnets            = var.subnets

  access_logs {
    bucket  = "${aws_s3_bucket.aws-module-lb-s3-bucket-logs.bucket}"
    enabled = true
  }
}

resource "aws_lb_target_group" "aws-module-lb-target-group" {
  count       = "${length(var.served_ports)}"
  name        = "${var.namespace}-tg-${var.served_ports[count.index]}"
  port        = "${
    (
      element(var.inner_served_ports, count.index) != 0
    ) ? 
    var.inner_served_ports[count.index] : 
    var.served_ports[count.index]
  }"
  protocol    = "${
    (
      length(var.inner_protocol) > 0
    ) ? 
    var.inner_protocol : 
    var.protocol
  }"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"

  depends_on  = [
    "aws_lb_listener.aws-module-lb-alb-listener"
  ]
}

resource "aws_lb_listener" "aws-module-lb-alb-listener" {
  count             = "${var.lb_type == "application" ? length(var.served_ports) : 0}"
  load_balancer_arn = "${aws_lb.aws-module-lb-lb.arn}"
  port              = "${var.served_ports[count.index]}"
  protocol          = "${var.protocol}"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${var.certificate_arn}"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener" "aws-module-lb-nlb-listener" {
  count             = "${var.lb_type == "application" ? 0 : length(var.served_ports)}"
  load_balancer_arn = "${aws_lb.aws-module-lb-lb.arn}"
  port              = "${var.served_ports[count.index]}"
  protocol          = "${var.protocol}"
  ssl_policy        = "${var.lb_type == "application" ? "ELBSecurityPolicy-2016-08" : null}"
  certificate_arn   = "${var.lb_type == "application" ? var.certificate_arn : null}"

  default_action {
    type = "forward"

    target_group_arn = "${aws_lb_target_group.aws-module-lb-target-group[0].arn}"
  }
}
