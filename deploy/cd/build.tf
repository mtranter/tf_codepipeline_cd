resource "aws_s3_bucket" "tf_aws_cd" {
  bucket = "tf-aws-cd-build"
  acl    = "private"
}

resource "aws_iam_role" "tf_aws_cd" {
  name = "tf_aws_cd_builder"

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

resource "aws_iam_role_policy" "tf_codepipeline_cd_role" {
  role = "${aws_iam_role.tf_aws_cd.name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "apigateway:*",
        "lambda:*",
        "iam:CreateRole"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.tf_aws_cd.arn}",
        "${aws_s3_bucket.tf_aws_cd.arn}/*",
        "${aws_s3_bucket.tf_aws_cd_pipeline.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "tf_codepipeline_cd_build" {
  name          = "tf_codepipeline_cd_build"
  description   = "tf_codepipeline_cd_build"
  build_timeout = "10"
  service_role  = "${aws_iam_role.tf_aws_cd.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = "${aws_s3_bucket.tf_aws_cd.bucket}"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/golang:1.11"
    type         = "LINUX_CONTAINER"
  }

  source {
    type            = "CODEPIPELINE"
  }
}