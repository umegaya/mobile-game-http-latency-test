variable "namespace" {
  type = string
}

output "cluster_name" {
  value = "${aws_ecs_cluster.aws-module-ecs-cluster.name}"
}
output "cluster_id" {
  value = "${aws_ecs_cluster.aws-module-ecs-cluster.id}"
}
output "service_role_arn" {
  value = "${aws_iam_role.aws-module-ecs-service-role.arn}"
}