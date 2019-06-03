resource "aws_vpc" "aws-module-nw-vpc" {
  cidr_block = "${var.vpc_cidr_block}"

  tags = {
    Name = "${var.namespace}"
  }
}

resource "aws_internet_gateway" "aws-module-nw-internet-gateway" {
  vpc_id = "${aws_vpc.aws-module-nw-vpc.id}"
  tags = {
    Name = "${var.namespace}"
  }
}

resource "aws_route_table" "aws-module-nw-route-to-internet" {
  vpc_id = "${aws_vpc.aws-module-nw-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.aws-module-nw-internet-gateway.id}"
  }
}

data "aws_availability_zones" "available" {
  blacklisted_names = var.blacklisted_zones
}

resource "aws_subnet" "aws-module-nw-subnet" {
  count      = var.subnet_count
  vpc_id     = "${aws_vpc.aws-module-nw-vpc.id}"
  cidr_block = replace(var.vpc_cidr_block, "/([0-9]+)\\.([0-9]+)\\.[0-9]+\\.([0-9]+)\\/([0-9]+)/", "$1.$2.${count.index + 1}.$3/24")
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "aws-module-nw-instance-security-group" {
  name = "${var.namespace}-instance"
  description = "Allow necessary inbound traffic for backend node"
  vpc_id      = "${aws_vpc.aws-module-nw-vpc.id}"

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

resource "aws_security_group" "aws-module-nw-lb-security-group" {
  name        = "${var.namespace}-lb"
  description = "Allow necessary inbound traffic for latency research http2 lb"
  vpc_id      = "${aws_vpc.aws-module-nw-vpc.id}"

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

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "aws-module-nw-s3-bucket-logs" {
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

resource "aws_lb" "aws-module-nw-lb" {
  name               = "${var.namespace}-lb"
  internal           = false
  load_balancer_type = "${var.lb_type}"
  security_groups    = ["${aws_security_group.aws-module-nw-lb-security-group.id}"]
  subnets            = ["${aws_subnet.aws-module-nw-subnet.0.id}", "${aws_subnet.aws-module-nw-subnet.1.id}"]

  enable_deletion_protection = true

  access_logs {
    bucket  = "${aws_s3_bucket.aws-module-nw-s3-bucket-logs.bucket}"
    enabled = true
  }
}
