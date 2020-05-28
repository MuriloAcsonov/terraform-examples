locals {
  availability_zones = ["${var.region}a", "${var.region}c"]
}

provider "aws" {
  region  = var.region  
}

module "network" {
  source               = "./modules/network"
  environment          = var.env
  vpc_cidr             = "10.0.0.0/16"
  public_subnets_cidr  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets_cidr = ["10.0.10.0/24", "10.0.20.0/24"]
  region               = var.region
  availability_zones   = local.availability_zones
}

module "ecs" {
  source              = "./modules/ecs"
  region              = var.region
  app_name            = "api-comments"
  environment         = "prod"
  vpc_id              = module.network.vpc_id
  subnets_ids         = module.network.private_subnets_id
  public_subnet_ids   = module.network.public_subnets_id
  security_groups_ids = [
    module.network.security_groups_ids
  ]
}

module "code_pipeline" {
  source                      = "./modules/code_pipeline"
  repository_url              = module.ecs.repository_url
  region                      = var.region
  task_definition             = module.ecs.task_definition
  app_name                    = module.ecs.service_name
  ecs_cluster_name            = module.ecs.cluster_name
  run_task_subnet_id          = module.network.private_subnets_id[0]
  run_task_security_group_ids = [module.network.security_groups_ids, module.ecs.security_group_id]
  repo_owner                  = "MuriloAcsonov"
  repo_name                   = "murilo-acsonov"
  branch                      = "master"
}
