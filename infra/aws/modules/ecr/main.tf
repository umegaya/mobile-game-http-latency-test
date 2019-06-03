resource "aws_ecr_repository" "aws-module-ecr-repository" {
  name = "${var.namespace}"
}

