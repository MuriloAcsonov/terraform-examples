variable "app_name" {}

variable "task_definition" {}

variable "repo_owner" {
  description = "Owner of the git repo"
}

variable "repo_name" {
  description = "Name of the git repo"
}

variable "branch" {
  description = "Branch of the git repo to build"
}

variable "repository_url" {
  description = "ECR repository"
}

variable "region" {}

variable "ecs_cluster_name" {
  description = "The cluster that we will deploy"
}

variable "run_task_subnet_id" {
  description = "The subnet Id where single run task will be executed"
}

variable "run_task_security_group_ids" {
  type        = list(string)
  description = "The security group Ids attached where the single run task will be executed"
}
