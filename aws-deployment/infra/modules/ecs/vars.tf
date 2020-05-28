variable "app_name" {
  description = "App name"
}

variable "environment" {
  description = "Env to laundh service, etc"
}

variable "vpc_id" {
  description = "Id of VPC"
}

variable "security_groups_ids" {
  type        = list(string)
  description = "The SGs to use"
}

variable "subnets_ids" {
  type        = list(string)
  description = "The private subnets to use"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "The private subnets to use"
}

variable "region" {}