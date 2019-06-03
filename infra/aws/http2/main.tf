variable "root_domain" {}

module "lb" {
  source = "../modules/lb"

  namespace = "latency-research-http2"
  lb_type = "application" 
  vpc_cidr_block = "10.80.0.0/16"
  subnet_count = 2
  blacklisted_zones = ["ap-northeast-1b"] 
}

module "ecr" {
  source = "../modules/ecr"

  namespace = "latency-research-http2"
}

module "cert" {
  source = "../modules/cert"

  namespace = "latency-research-http2"
  root_domain = "${var.root_domain}"
  host_name_prefix = "latency-research-http2.service"
  lb_dns_name = "${module.lb.dns_name}"
}

module "ecs" {
  source = "../modules/ecs"
  
  namespace = "latency-research-http2"
  ecs_launch_type = "EC2"
  lb_target_group_arn = "${aws_lb_target_group.latency-research-http2-lb-target-group.arn}"
  container_definitions = <<DEFS
  [{
    "name": "websv",
    "image": "${module.ecr.repository_url}:latest",
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
}

module "ec2" {
  source = "../modules/ec2"

  namespace = "latency-research-http2"
  key_pair_cert = file("${path.module}/cert/id_rsa.pub")
  root_domain = "${var.root_domain}"
  instance_type = "t3.small"
  min_instance_size = 1
  max_instance_size = 2
  desired_instance_capacity = 1
  security_groups = ["${module.lb.instance_security_group}"]
  vpc_zone_identifier = [for sn in module.lb.subnets: sn.id]
  ecs_cluster_name = "${module.ecs.cluster_name}"
  cpu_utilization_threshold = 70.0
}

resource "aws_lb_target_group" "latency-research-http2-lb-target-group" {
  name        = "latency-research-http2"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "${module.lb.vpc_id}"

  depends_on  = [
    "aws_lb_listener.latency-research-http2-lb-listener"
  ]
}

resource "aws_lb_listener" "latency-research-http2-lb-listener" {
  load_balancer_arn = "${module.lb.arn}"
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${module.cert.certificate_arn}"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "latency-research-http2-listener-rule-api" {
  listener_arn = "${aws_lb_listener.latency-research-http2-lb-listener.arn}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.latency-research-http2-lb-target-group.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/api/*"]
  }
}

resource "aws_lb_listener_rule" "latency-research-http2-listener-rule-static" {
  listener_arn = "${aws_lb_listener.latency-research-http2-lb-listener.arn}"
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.latency-research-http2-lb-target-group.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/static/*"]
  }
}

resource "aws_autoscaling_attachment" "aws-module-ec2-autoscaling-attachment" {
  autoscaling_group_name = "${module.ec2.autoscaling_group_name}"
  alb_target_group_arn   = "${aws_lb_target_group.latency-research-http2-lb-target-group.arn}"
}
