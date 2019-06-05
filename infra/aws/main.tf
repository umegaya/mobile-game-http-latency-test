variable "root_domain" {}

module "nw" {
  source = "./modules/nw"

  namespace = "latency-research"
  vpc_cidr_block = "10.80.0.0/16"
  subnet_count = 2
  blacklisted_zones = ["ap-northeast-1b"] 
}

module "lb-rest" {
  source = "./modules/lb"

  namespace = "latency-research-rest"
  lb_type = "application" 
  vpc_id = "${module.nw.vpc_id}"
  served_ports = [443]
  inner_served_ports = [80]
  subnets = [for sn in module.nw.subnets: sn.id]
  protocol = "HTTPS"
  inner_protocol = "HTTP"
  certificate_arn = "${module.cert.certificates[0]}"
}

module "lb-grpc" {
  source = "./modules/lb"

  namespace = "latency-research-grpc"
  lb_type = "network" 
  vpc_id = "${module.nw.vpc_id}"
  served_ports = [50051]
  subnets = [for sn in module.nw.subnets: sn.id]
  protocol = "TCP"
  certificate_arn = "${module.cert.certificates[1]}"
}

module "ecr" {
  source = "./modules/ecr"

  namespace = "latency-research"
}

module "cert" {
  source = "./modules/cert"

  namespace = "latency-research"
  root_domain = "${var.root_domain}"
  cn_lb_mapping = [
    {cn = "latency-research.rest.service", dns = "${module.lb-rest.dns_name}"},
    {cn = "latency-research.grpc.service", dns = "${module.lb-grpc.dns_name}"}
  ]
}

module "ecs" {
  source = "./modules/ecs"
  
  namespace = "latency-research"
  ecs_launch_type = "EC2"
  lb_target_group_arn = "${module.lb-rest.target_group_arns[0]}"
  container_definitions = <<DEFS
  [{
    "name": "websv",
    "image": "${module.ecr.repository_url}:latest",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      },
      {
        "containerPort": 50051,
        "hostPort": 50051
      }
    ],
    "memory": 1536,
    "cpu": 768,
    "command": ["node", "index.js"]
  }]
DEFS
}

module "ec2" {
  source = "./modules/ec2"

  namespace = "latency-research"
  vpc_id = "${module.nw.vpc_id}"
  served_ports = [80, 50051]
  key_pair_cert = file("${path.module}/cert/id_rsa.pub")
  root_domain = "${var.root_domain}"
  instance_type = "t3.small"
  min_instance_size = 1
  max_instance_size = 2
  desired_instance_capacity = 1
  vpc_zone_identifier = [for sn in module.nw.subnets: sn.id]
  ecs_cluster_name = "${module.ecs.cluster_name}"
  cpu_utilization_threshold = 70.0
}


/*
  main.tf resources: rest
*/
resource "aws_lb_listener_rule" "latency-research-rest-listener-rule-api" {
  listener_arn = "${module.lb-rest.listener_arns[0]}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = "${module.lb-rest.target_group_arns[0]}"
  }

  condition {
    field  = "path-pattern"
    values = ["/api/*"]
  }
}

resource "aws_lb_listener_rule" "latency-research-http2-listener-rule-static" {
  listener_arn = "${module.lb-rest.listener_arns[0]}"
  priority     = 99

  action {
    //TODO: send to s3 bucket
    type             = "forward"
    target_group_arn = "${module.lb-rest.target_group_arns[0]}"
  }

  condition {
    field  = "path-pattern"
    values = ["/static/*"]
  }
}

resource "aws_autoscaling_attachment" "latency-research-rest-autoscaling-attachment" {
  autoscaling_group_name = "${module.ec2.autoscaling_group_name}"
  alb_target_group_arn   = "${module.lb-rest.target_group_arns[0]}"
}



/*
  main.tf resources: grpc
*/
resource "aws_autoscaling_attachment" "latency-research-grpc-autoscaling-attachment" {
  autoscaling_group_name = "${module.ec2.autoscaling_group_name}"
  alb_target_group_arn   = "${module.lb-grpc.target_group_arns[0]}"
}