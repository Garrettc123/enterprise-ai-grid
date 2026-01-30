# Enterprise AI Grid - Main Infrastructure
# Developed by Garrett Carrol

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  backend "s3" {
    bucket         = "enterprise-ai-grid-tfstate"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "EnterpriseAIGrid"
      ManagedBy   = "Terraform"
      Owner       = "GarrettCarrol"
      Environment = var.environment
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "enterprise-ai-grid"
}

# VPC Configuration
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

# EKS Cluster
module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  node_groups = {
    ultra_performance = {
      instance_types = ["c7g.16xlarge"]
      desired_size   = 3
      min_size       = 3
      max_size       = 10
    }
  }
}

# RDS Database
module "rds" {
  source = "./modules/rds"

  identifier        = "${var.cluster_name}-db"
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.r6g.2xlarge"
  allocated_storage = 100

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

# S3 Storage
module "s3" {
  source = "./modules/s3"

  bucket_name = "${var.cluster_name}-data"

  versioning_enabled = true
  encryption_enabled = true
}

# Outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  value = module.rds.endpoint
}
