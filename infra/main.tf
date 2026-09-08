terraform {
  backend "s3" {
    bucket       = "threatlens-terraform-state-113462084471"
    key          = "threatlens/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
}

module "vpc" {
  source = "./modules/vpc"

  name               = "threatlens"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-west-2a", "eu-west-2b"]
}

module "ecr" {
  source = "./modules/ecr"

  repository_name = "threatlens"
}

module "iam" {
  source = "./modules/iam"

  execution_role_name = "threatlens-ecs-execution-role"
}

module "security_groups" {
  source = "./modules/security-groups"

  vpc_id = module.vpc.vpc_id
}

module "ecs" {
  source = "./modules/ecs"

  cluster_name       = "threatlens"
  task_family        = "threatlens"
  cpu                = 256
  memory             = 512
  execution_role_arn = module.iam.execution_role_arn
  container_name     = "threatlens"
  container_image    = "${module.ecr.repository_url}:latest"
  service_name       = "threatlens"

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security_groups.ecs_security_group_id]
  target_group_arn   = module.alb.target_group_arn

  aws_region = "eu-west-2"
}

module "alb" {
  source = "./modules/alb"

  name               = "threatlens-alb"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.alb_security_group_id]
  certificate_arn    = module.acm.certificate_arn
}

module "acm" {
  source = "./modules/acm"

  domain_name = "tm.threatlenslab.com"
}

module "route53" {
  source = "./modules/route53"

  domain_name  = "threatlenslab.com"
  record_name  = "tm"
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id

  certificate_domain_validation_options = module.acm.domain_validation_options
}

module "monitoring" {
  source = "./modules/monitoring"

  cluster_name             = "threatlens"
  service_name             = "threatlens"
  load_balancer_arn_suffix = module.alb.load_balancer_arn_suffix
  target_group_arn_suffix  = module.alb.target_group_arn_suffix
}