terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
  # backend "s3" {
  #   bucket         = "prod-platform-tfstate"
  #   key            = "aws/terraform.tfstate"
  #   region         = "eu-west-1"
  #   dynamodb_table = "tfstate-locks"
  # }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "eu-west-1" # EU data-residency enforcement
}

# Provider layer abstraction
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "platform-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

# Production RDS Aurora PostgreSQL
resource "aws_db_subnet_group" "rds" {
  name       = "platform-rds-subnets"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_rds_cluster" "postgresql" {
  cluster_identifier      = "platform-aurora-pg"
  engine                  = "aurora-postgresql"
  engine_version          = "15.4"
  database_name           = "platform_db"
  master_username         = "app_admin"
  manage_master_user_password = true
  db_subnet_group_name    = aws_db_subnet_group.rds.name
  skip_final_snapshot     = true
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 2
  identifier         = "platform-aurora-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.postgresql.id
  instance_class     = "db.r6g.xlarge"
  engine             = aws_rds_cluster.postgresql.engine
  engine_version     = aws_rds_cluster.postgresql.engine_version
}

# Production Redis (ElastiCache)
resource "aws_elasticache_subnet_group" "redis" {
  name       = "platform-redis-subnets"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "platform-redis-cluster"
  description                = "Redis job queue cluster"
  node_type                  = "cache.m6g.large"
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  port                       = 6379
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
}