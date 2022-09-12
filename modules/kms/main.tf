resource "aws_kms_key" "default" {
  description             = "KMS Key for ${var.resource_name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "default" {
  name          = format("alias/kms-%s", replace(var.resource_name, "/", "-"))
  target_key_id = aws_kms_key.default.key_id
}
