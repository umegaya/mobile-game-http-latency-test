resource "aws_placement_group" "latency-research-http2" {
  name     = "latency-research-http2"
  strategy = "spread"
}

resource "aws_launch_configuration" "latency-research-http2" {
  name          = "latency-research-http2"
  image_id      = "${data.aws_ami.ubuntu.id}"
  # cluster placement cannot be apply to all instance type. 
  instance_type = "t3.small"
}

resource "aws_autoscaling_group" "latency-research-http2" {
  name                      = "latency-research-http2"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  placement_group           = "${aws_placement_group.latency-research-http2.id}"
  launch_configuration      = "${aws_launch_configuration.latency-research-http2.name}"
  vpc_zone_identifier       = ["${aws_subnet.latency-research-http2[0].id}", "${aws_subnet.latency-research-http2[1].id}"]

  /* initial_lifecycle_hook {
    name                 = "foobar"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

    notification_metadata = <<EOF
{
  "foo": "bar"
}
EOF

    notification_target_arn = "arn:aws:sqs:us-east-1:444455556666:queue1*"
    role_arn                = "arn:aws:iam::123456789012:role/S3Access"
  }

  tag {
    key                 = "foo"
    value               = "bar"
    propagate_at_launch = true
  } */

  timeouts {
    delete = "15m"
  }

  /*tags = [{
    key                 = "Name"
    value               = "ipsum"
    propagate_at_launch = false
  }]*/
}

resource "aws_autoscaling_policy" "latency-research-http2" {
  name                   = "latency-research-http2"
  autoscaling_group_name = "${aws_autoscaling_group.latency-research-http2.name}"
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70.0
  }
}
