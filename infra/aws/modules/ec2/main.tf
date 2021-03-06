resource "aws_placement_group" "aws-module-ec2-placement-group" {
  name     = "${var.namespace}"
  strategy = "spread"
}

resource "aws_key_pair" "aws-module-ec2-key-pair" {
  key_name   = "${var.namespace}-key-pair"
  public_key = "${var.key_pair_cert}"
}

resource "aws_iam_role" "aws-module-ec2-instance-role" {
  name = "${var.namespace}-ecsInstanceRole"

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

resource "aws_iam_role_policy_attachment" "aws-module-ec2-instance-role-policy-attachement" {
  role = "${aws_iam_role.aws-module-ec2-instance-role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}


resource "aws_iam_instance_profile" "aws-module-ec2-instance-profile" {
  name = "${var.namespace}-ecsInstanceRole"
  role = "${aws_iam_role.aws-module-ec2-instance-role.name}"
}

data "template_file" "aws-module-ec2-userdata" {
  template = "${file("${path.module}/templates/userdata.sh.tpl")}"

  vars = {
    ecs_cluster = "${var.ecs_cluster_name}"
  }
}

data "aws_ami" "aws-module-ec2-ami-id" {
  most_recent = true

  filter {
    name   = "image-id"
    values = ["ami-0e52aad6ac7733a6a"]
  }

  owners = ["591542846629"] // amazon
}

resource "aws_security_group" "aws-module-ec2-security-group" {
  name = "${var.namespace}-instance"
  description = "Allow necessary inbound traffic for backend node"
  vpc_id      = "${var.vpc_id}"

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

resource "aws_security_group_rule" "aws-module-ec2-security-group-rule" {
  count           = "${length(var.served_ports)}"
  type            = "ingress"
  from_port       = "${var.served_ports[count.index]}"
  to_port         = "${var.served_ports[count.index]}"
  protocol        = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = "${aws_security_group.aws-module-ec2-security-group.id}"
}


resource "aws_launch_configuration" "aws-module-ec2-launch-configuration" {
  name          = "${var.namespace}"
  image_id      = "${data.aws_ami.aws-module-ec2-ami-id.id}"
  # cluster placement cannot be apply to all instance type. 
  instance_type = "${var.instance_type}"
  key_name      = "${aws_key_pair.aws-module-ec2-key-pair.key_name}"
  security_groups = ["${aws_security_group.aws-module-ec2-security-group.id}"]
  user_data       = "${data.template_file.aws-module-ec2-userdata.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.aws-module-ec2-instance-profile.name}"
}

resource "aws_autoscaling_group" "aws-module-ec2-autoscaling-group" {
  name                      = "${var.namespace}"
  max_size                  = "${var.max_instance_size}"
  min_size                  = "${var.min_instance_size}"
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = "${var.desired_instance_capacity}"
  force_delete              = true
  placement_group           = "${aws_placement_group.aws-module-ec2-placement-group.id}"
  launch_configuration      = "${aws_launch_configuration.aws-module-ec2-launch-configuration.name}"
  vpc_zone_identifier       = var.vpc_zone_identifier

  timeouts {
    delete = "15m"
  }
}

resource "aws_autoscaling_policy" "aws-module-ec2-autoscaling-policy" {
  name                   = "${var.namespace}"
  autoscaling_group_name = "${aws_autoscaling_group.aws-module-ec2-autoscaling-group.name}"
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = "${var.cpu_utilization_threshold}"
  }
}

