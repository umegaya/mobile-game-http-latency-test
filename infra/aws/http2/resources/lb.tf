resource "aws_vpc" "latency-research-http2" {
  cidr_block = "10.80.0.0/16"

  tags = {
    Name = "latency-research-http2"    
  }
}

resource "aws_internet_gateway" "latency-research-http2" {
    vpc_id = "${aws_vpc.latency-research-http2.id}"
    tags = {
        Name = "latency-research-http2"
    }
}

resource "aws_security_group" "latency-research-http2" {
  name        = "latency-research-http2"
  description = "Allow necessary inbound traffic for latency research http2"
  vpc_id      = "${aws_vpc.latency-research-http2.id}"

  ingress {
    # TLS
    from_port   = 443
    to_port     = 443
    protocol    = "-1"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "latency-research-http2" {
  count      = 2
  vpc_id     = "${aws_vpc.latency-research-http2.id}"
  cidr_block = "10.80.${count.index + 1}.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
}

resource "aws_s3_bucket" "latency-research-http2-lb-logs" {
  bucket = "latency-research-http2-lb-logs"
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
      "Resource": "arn:aws:s3:::latency-research-http2-lb-logs/*",
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

resource "aws_lb" "latency-research-http2" {
  name               = "latency-research-http2-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.latency-research-http2.id}"]
  subnets            = ["${aws_subnet.latency-research-http2[0].id}", "${aws_subnet.latency-research-http2[1].id}"]

  enable_deletion_protection = true

  access_logs {
    bucket  = "${aws_s3_bucket.latency-research-http2-lb-logs.bucket}"
    enabled = true
  }
}

resource "aws_lb_target_group" "latency-research-http2" {
  name        = "latency-research-http2"
  port        = 443
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = "${aws_vpc.latency-research-http2.id}"
}

resource "aws_autoscaling_attachment" "latency-research-http2" {
  autoscaling_group_name = "${aws_autoscaling_group.latency-research-http2.id}"
  alb_target_group_arn   = "${aws_lb_target_group.latency-research-http2.arn}"
}

