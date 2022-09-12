///////////////////////////////////////
////cloudwatch
////////////////

resource "aws_iam_role" "cwe_role" {
  name               = "${var.environment}-cwe-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": ["events.amazonaws.com"]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "cwe_policy" {

  name   = "${var.environment}-cwe-role-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "codepipeline:StartPipelineExecution"
        ],
        "Resource": [
            "${aws_codepipeline.ecs_pipeline.arn}"
        ]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "cws_policy_attachment" {
  name       = "${var.environment}-cwe-role-policy-attachment"
  roles      = [aws_iam_role.cwe_role.name]
  policy_arn = aws_iam_policy.cwe_policy.arn
}

///////////////////////////////////////
////codepipeline
////////////////


resource "aws_iam_role" "codepipeline_role" {

  name               = "${var.environment}-codepipeline-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codepipeline_policy" {
  name   = "${var.environment}-codepipeline-role-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.s3_bucket.arn}",
        "${aws_s3_bucket.s3_bucket.arn}/*"
      ]
    },
    {
      "Effect":"Allow",
      "Action": [
              "codebuild:BatchGetBuilds",
              "codebuild:StartBuild" ],
      "Resource":["${aws_codebuild_project.ecs_build.arn}"]
    },
{
    "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetApplicationRevision",
        "codedeploy:GetApplication",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision"
    ],
    "Resource": ["${aws_codedeploy_app.default.arn}","${aws_codedeploy_deployment_group.default.arn}","arn:aws:codedeploy:${var.aws_region}:${data.aws_caller_identity.current.account_id}:deploymentconfig:*"],
    "Effect": "Allow"
},
{
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateService"
      ],
      "Resource": "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.ecs_service_name}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeTasks",
        "ecs:ListTasks",
        "ecs:RegisterTaskDefinition"
      ],
      "Resource": "*"
    },
{
      "Effect": "Allow",
      "Action": [
        "ecr:*"
      ],
      "Resource": "${data.terraform_remote_state.ecr.outputs.arn}"
    },

{
            "Action": [
                "iam:PassRole"
            ],
            "Resource": ["${aws_iam_role.ecs_cluster_ecstaskrole.arn}"],
            "Effect": "Allow",
            "Condition": {
                "StringEqualsIfExists": {
                    "iam:PassedToService": [
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "codepipeline_role_policy_attachment" {
  name       = "${var.environment}-codepipeline-role-policy-attachment"
  roles      = [aws_iam_role.codepipeline_role.name]
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}


///////////////////////////////////////
////codedeploy
////////////////

resource "aws_iam_role" "iam-rle-ecs-codedeploy" {
  name = "${var.environment}-codedeploy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "iam-ply-codedeploy" {
  name = "${var.environment}-codedeploy-role-policy"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow",
      Action   = ["iam:PassRole"],
      Resource = ["${aws_iam_role.ecs_cluster_ecstaskrole.arn}"]
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:UpdateServicePrimaryTaskSet",
        "ecs:DeleteTaskSet"]
        Resource = ["arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${local.ecs_cluster_name}/${local.ecs_service_name}",
        "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-set/${local.ecs_cluster_name}/${local.ecs_service_name}/*"]
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:DescribeServices",
          "ecs:CreateTaskSet",
        "cloudwatch:DescribeAlarms"],
        Resource = ["*"]
        }, {
        Effect   = "Allow",
        Action   = ["sns:Publish", ],
        Resource = ["arn:aws:sns:*:*:CodeDeployTopic_*"]
      },
      {
        Effect = "Allow",
        Action = [
        "elasticloadbalancing:ModifyListener"],
        Resource = [aws_alb_listener.ecs_alb_http_listener.arn,
        aws_alb_listener.ecs_alb_test_listener.arn]
      },
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:ModifyRule"],
        Resource = ["*"]
        }, {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectMetadata",
        "s3:GetObjectVersion", ],
        Condition = {
          StringEquals = {
            "s3:ExistingObjectTag/UseWithCodeDeploy" = "true"
          }
        },
        Resource = ["*"]
    }]
  })
}
# https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html
resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.iam-rle-ecs-codedeploy.name
  policy_arn = aws_iam_policy.iam-ply-codedeploy.arn
}


///////////////////////////////////////
////codebuild
////////////////

resource "aws_iam_role" "codebuild" {
  name               = "${var.environment}-codebuild-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "codebuild" {
  role   = aws_iam_role.codebuild.name
  name   = "${var.environment}-codebuild-role-policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },{
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeTaskDefinition" ],
      "Resource": [ "*" ]
    },
{
      "Effect": "Allow",
      "Action": [
        "ecr:*"
      ],
      "Resource": "${data.terraform_remote_state.ecr.outputs.arn}"
    },
{
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
"Resource": [
        "${aws_s3_bucket.s3_bucket.arn}",
        "${aws_s3_bucket.s3_bucket.arn}/*"
      ]
    }
  ]
}
POLICY
}
