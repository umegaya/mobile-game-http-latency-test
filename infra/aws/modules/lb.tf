resource "aws_vpc" "aws-module-lb-vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "${var.namespace}"
  }
}

resource "aws_internet_gateway" "aws-module-lb-internet-gateway" {
  vpc_id = "${aws_vpc.aws-module-lb-vpc.id}"
  tags = {
    Name = "${var.namespace}"
  }
}

resource "aws_route_table" "aws-module-lb-route-to-internet" {
  vpc_id = "${aws_vpc.aws-module-lb-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.aws-module-lb-internet-gateway.id}"
  }
}

resource "aws_security_group" "aws-module-lb-instance-security-group" {
  name = "${var.namespace}"
  description = "Allow necessary inbound traffic for backend node"
  vpc_id      = "${aws_vpc.aws-module-lb-vpc.id}"

  ingress {
    # http
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    # SSH
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "aws-module-lb-lb-security-group" {
  name        = "${var.namespace}"
  description = "Allow necessary inbound traffic for latency research http2 lb"
  vpc_id      = "${aws_vpc.aws-module-lb-vpc.id}"

  ingress {
    # https
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_availability_zones" "available" {
  blacklisted_names = var.blacklisted_zones
}

resource "aws_subnet" "aws-module-lb-subnet" {
  count      = 2
  vpc_id     = "${aws_vpc.aws-module-lb-vpc.id}"
  cidr_block = "10.80.${count.index + 1}.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "aws-module-lb-s3-bucket-logs" {
  bucket = "${var.namespace}-lb-logs"
  acl    = "private"

  policy = <<POLICY
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
POLICY
}

resource "aws_lb" "aws-module-lb-lb" {
  name               = "${var.namespace}-lb"
  internal           = false
  load_balancer_type = "${var.lb_type}"
  security_groups    = ["${aws_security_group.aws-module-lb-lb-security-group.id}"]
  subnets            = ["${aws_subnet.aws-module-lb-subnet.0.id}", "${aws_subnet.aws-module-lb-subnet.1.id}"]

  enable_deletion_protection = true

  access_logs {
    bucket  = "${aws_s3_bucket.aws-module-lb-s3-bucket-logs.bucket}"
    enabled = true
  }
}

resource "aws_lb_target_group" "aws-module-lb-target-group" {
  name        = "${var.namespace}"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "${aws_vpc.aws-module-lb-vpc.id}"
}

resource "aws_lb_listener" "aws-module-lb-listener" {
  load_balancer_arn = "${aws_lb.aws-module-lb-lb.arn}"
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${aws_acm_certificate.aws-module-cert-certificate.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.aws-module-lb-target-group.arn}"
  }
}

resource "aws_route53_record" "aws-module-lb-lb-dns-record" {
  zone_id = "${aws_route53_zone.aws-module-cert-zone.zone_id}"
  name    = "${var.host_name_prefix}.${var.root_domain}"
  type    = "CNAME"
  ttl     = "3600"
  records = ["${aws_lb.aws-module-lb-lb.dns_name}"]
}
