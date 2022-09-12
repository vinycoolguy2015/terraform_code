module "kms" {
  source        = "../../modules/kms"
  resource_name = "ecr-${var.environment}"
}

resource "aws_ecr_repository" "ecr_repo" {
  name                 = "ecr-${var.environment}"
  image_tag_mutability = var.tag_mutability #tfsec:ignore:aws-ecr-enforce-immutable-repository
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = module.kms.arn
  }
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "ecr_repo_policy" {
  repository = aws_ecr_repository.ecr_repo.name
  policy     = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last n images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["v"],
                "countType": "imageCountMoreThan",
                "countNumber": ${var.image_count}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
