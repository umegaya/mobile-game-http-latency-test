variable "root_domain" {}

module "lb" {
  source = "../modules/lb"

  namespace = "latency-research-grpc"
  lb_type = "network" 
  vpc_cidr_block = "10.81.0.0/16"
  subnet_count = 2
  blacklisted_zones = ["ap-northeast-1b"] 
}

module "ecr" {
  source = "../modules/ecr"

  namespace = "latency-research-grpc"
}

module "cert" {
  source = "../modules/cert"

  namespace = "latency-research-grpc"
  root_domain = "${var.root_domain}"
  host_name_prefix = "latency-research-grpc.service"
  lb_dns_name = "${module.lb.dns_name}"
}

module "ecs" {
  source = "../modules/ecs"
  
  namespace = "latency-research-grpc"
  ecs_launch_type = "EC2"
  lb_target_group_arn = "${aws_lb_target_group.latency-research-grpc-lb-target-group.arn}"
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

  namespace = "latency-research-grpc"
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

resource "aws_lb_target_group" "latency-research-grpc-lb-target-group" {
  name        = "latency-research-grpc"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "${module.lb.vpc_id}"

  depends_on  = [
    "aws_lb_listener.latency-research-grpc-lb-listener"
  ]
}

resource "aws_lb_listener" "latency-research-grpc-lb-listener" {
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

resource "aws_autoscaling_attachment" "aws-module-ec2-autoscaling-attachment" {
  autoscaling_group_name = "${module.ec2.autoscaling_group_name}"
  alb_target_group_arn   = "${aws_lb_target_group.latency-research-grpc-lb-target-group.arn}"
}
