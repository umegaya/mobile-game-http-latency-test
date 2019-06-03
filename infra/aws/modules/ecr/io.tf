variable "namespace" {
  type = string
}

output "repository_url" {
  value = "${aws_ecr_repository.aws-module-ecr-repository.repository_url}"
}
