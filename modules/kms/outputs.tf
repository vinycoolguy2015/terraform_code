output "arn" {
  value = aws_kms_key.default.arn
}

output "alias_arn" {
  value = aws_kms_alias.default.arn
}

output "alias" {
  value = "alias/kms-${var.resource_name}"
}
