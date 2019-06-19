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
  target_group_ports = [80, 8080]
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
}

module "ecs-task-api" {
  source = "./modules/ecs-task"

  namespace = "latency-research"

  ecs_launch_type = "EC2"
  service_role_arn = "${module.ecs.service_role_arn}"
  container_name = "websv"
  container_forwarded_port = 80
  ecs_cluster_id = "${module.ecs.cluster_id}"
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

module "ecs-task-static" {
  source = "./modules/ecs-task"

  namespace = "latency-research"

  ecs_launch_type = "EC2"
  service_role_arn = "${module.ecs.service_role_arn}"
  container_name = "static"
  container_forwarded_port = 8080
  ecs_cluster_id = "${module.ecs.cluster_id}"
  lb_target_group_arn = "${module.lb-rest.target_group_arns[1]}"
  container_definitions = <<DEFS
  [{
    "name": "static",
    "image": "${module.ecr.repository_url}:static",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ],
    "memory": 384,
    "cpu": 256,
    "environment": [
      { "name": "REDIRECT_TO", "value": "https://${aws_s3_bucket.latency-research-static-files-bucket.bucket_regional_domain_name}" }
    ]
  }]
DEFS
}

module "ec2" {
  source = "./modules/ec2"

  namespace = "latency-research"
  vpc_id = "${module.nw.vpc_id}"
  served_ports = [80, 50051, 8080]
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
  main.tf resources: static
 */
resource "aws_s3_bucket" "latency-research-static-files-bucket" {
  bucket = "latency-research-static-files"
  acl    = "public-read"
}

locals {
  files = [
    "capitol-2212102_1280.jpg",
    "jordan-1846284_1280.jpg",
    "sunset-4274662_1280.jpg",
    "hanoi-4176310_1280.jpg",
    "mirror-house-4278611_1280.jpg"
  ]
}

resource "aws_s3_bucket_object" "latency-research-static-files" {
  count = length(local.files)
  bucket = "${aws_s3_bucket.latency-research-static-files-bucket.bucket}"
  key    = "static/${local.files[count.index]}"
  acl    = "public-read"
  source = pathexpand("${path.module}/../resources/${local.files[count.index]}")
  etag = "${filemd5(pathexpand("${path.module}/../resources/${local.files[count.index]}"))}"
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
    type             = "forward"
    target_group_arn = "${module.lb-rest.target_group_arns[1]}"
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