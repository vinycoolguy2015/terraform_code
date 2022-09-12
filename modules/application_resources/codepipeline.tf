resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.environment}-codepipeline-bucket-2022"
}

resource "aws_s3_bucket_public_access_block" "s3_public_access_block" {
  bucket                  = aws_s3_bucket.s3_bucket.id
  ignore_public_acls      = true
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
}


resource "aws_cloudwatch_event_rule" "image_push" {
  name          = "${var.environment}-cw-event-rule"
  role_arn      = aws_iam_role.cwe_role.arn
  event_pattern = <<EOF
{
  "source": [
    "aws.ecr"
  ],
  "detail": {
    "action-type": [
      "PUSH"
    ],
    "image-tag": [
      "latest"
    ],
    "repository-name": [
      "ecr-${var.environment}"
    ],
    "result": [
      "SUCCESS"
    ]
  },
  "detail-type": [
    "ECR Image Action"
  ]
}
EOF
}

resource "aws_cloudwatch_event_target" "codepipeline" {
  rule      = aws_cloudwatch_event_rule.image_push.name
  target_id = "${var.environment}-image-api"
  arn       = aws_codepipeline.ecs_pipeline.arn
  role_arn  = aws_iam_role.cwe_role.arn
}

resource "aws_codepipeline" "ecs_pipeline" {
  name     = "${var.environment}-ecs-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.s3_bucket.bucket
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name             = "ImagePush"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      output_artifacts = ["Image"]
      configuration = {
        RepositoryName = "ecr-${var.environment}"
        ImageTag       = "latest"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["Image"]
      output_artifacts = ["BuildArtifact"]
      version          = "1"

      configuration = {
        ProjectName   = aws_codebuild_project.ecs_build.id
        PrimarySource = "SourceArtifact"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name      = "Deploy"
      category  = "Deploy"
      owner     = "AWS"
      provider  = "CodeDeployToECS"
      version   = "1"
      run_order = 1
      input_artifacts = [
        "BuildArtifact"
      ]
      configuration = {
        ApplicationName                = aws_codedeploy_app.default.name
        DeploymentGroupName            = split("/", aws_codedeploy_deployment_group.default.arn)[1]
        TaskDefinitionTemplateArtifact = "BuildArtifact"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "BuildArtifact"
        AppSpecTemplatePath            = "appspec.yaml"
        Image1ArtifactName             = "BuildArtifact"
        Image1ContainerName            = "IMAGE1_NAME"
      }
    }
  }
}

