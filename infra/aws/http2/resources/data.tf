data "aws_availability_zones" "available" {
  blacklisted_names = ["ap-northeast-1b"]
}
data "aws_elb_service_account" "main" {}

data "aws_ami" "latency-research-http2" {
  most_recent = true

  filter {
    name   = "image-id"
    values = ["ami-0e52aad6ac7733a6a"]
  }

    owners = ["591542846629"] // amazon
}

data "local_file" "latency-research-http2-cert" {
  filename = "${path.module}/cert/id_rsa.pub"
}

data "template_file" "latency-research-http2-ec2-userdata" {
  template = "${file("${path.module}/templates/userdata.sh.tpl")}"

  vars = {
    ecs_cluster = "${aws_ecs_cluster.latency-research-http2.name}"
  }
}
