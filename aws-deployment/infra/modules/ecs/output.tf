output "repository_url" {
  value = aws_ecr_repository.repo_app.repository_url
}

output "cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "service_name" {
  value = aws_ecs_service.ecs_service.name
}

output "alb_dns_name" {
  value = aws_alb.alb.dns_name
}

output "alb_zone_id" {
  value = aws_alb.alb.zone_id
}

output "security_group_id" {
  value = aws_security_group.ecs_service_sg.id
}

output "task_definition" {
  value = aws_ecs_task_definition.task_definition.family
}