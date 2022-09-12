output "registry" {
  value = aws_ecr_repository.ecr_repo.repository_url
}

output "ecr_kms_arn" {
  value = module.kms.arn
}

output "arn" {
  value = aws_ecr_repository.ecr_repo.arn
}
