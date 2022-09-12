data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = {
    bucket = var.bucket
    key    = format("environments/%s/ecr/terraform.tfstate", var.environment)
    region = var.aws_region
  }
}
