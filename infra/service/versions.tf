terraform {
  required_version = ">= 1.10.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {}
}
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
      Purpose   = "TechnicalChallenge"
    }
  }
}
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project_name" {
  type    = string
  default = "banbif-demo"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,17}$", var.project_name))
    error_message = "Use 3-18 lowercase letters, numbers or hyphens, beginning with a letter."
  }
}
