locals {
  config      = read_terragrunt_config(find_in_parent_folders("inputs.hcl"))
  aws_region  = local.config.inputs.aws_region
  account_id  = local.config.inputs.account_id
  environment = split("/", get_path_from_repo_root())[1]
}

remote_state {
  backend = "s3"
  config = {
    bucket         = local.config.inputs.bucket
    key            = format("%s/terraform.tfstate", get_path_from_repo_root())
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = local.config.inputs.dynamodb_table
  }
}



generate "common_variables" {
  path      = "common_variables.tf"
  if_exists = "overwrite"
  contents  = <<EOF
variable "aws_region" {
  description = "Region to deploy current terraform script"
  default     = "ap-southeast-1"
}

variable "bucket" {
  description = "The S3 bucket for terraform_remote_state"
  default     = "terraform-state-2022"
}

variable "environment" {
  description = "environment name - test/staging/production"
}


data "aws_default_tags" "metadata" {}

data "aws_caller_identity" "current" {}


terraform {
  backend "s3" {}
  required_providers {
    aws  = "~> 4.0.0"
  }
}

provider "aws" {
  region = "ap-southeast-1"
  default_tags {
    tags = {
      Environment  = "${local.environment}"
      Terraform    = "true"
    }
  }
}


EOF
}

inputs = {
  environment = local.environment
  bucket      = local.config.inputs.bucket
  aws_region  = local.config.inputs.aws_region
}
