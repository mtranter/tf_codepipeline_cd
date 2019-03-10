resource "aws_s3_bucket" "tf_aws_cd_pipeline" {
  bucket = "tf-aws-cd-pipeline"
  acl    = "private"
}

resource "aws_iam_role" "tf_aws_cd_pipeline" {
  name = "tf-aws-cd-pipeline"

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

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = "${aws_iam_role.tf_aws_cd_pipeline.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.tf_aws_cd_pipeline.arn}",
        "${aws_s3_bucket.tf_aws_cd_pipeline.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

data "aws_ssm_parameter" "webhooks_secret" {
    name = "/github/tf_codepipeline_cd/webhooks/secret"
}

data "aws_ssm_parameter" "github_secret" {
    name = "/github/tf_codepipeline_cd/secret"
}
resource "aws_codepipeline" "tf_aws_cd_pipeline" {
  name     = "tf-aws-cd-pipeline"
  role_arn = "${aws_iam_role.tf_aws_cd_pipeline.arn}"

  artifact_store {
    location = "${aws_s3_bucket.tf_aws_cd_pipeline.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        Owner  = "mtranter"
        Repo   = "tf_codepipeline_cd"
        Branch = "master"
        PollForSourceChanges = "false"
        OAuthToken = "${data.aws_ssm_parameter.github_secret.value}"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      output_artifacts = ["test"]
      input_artifacts = ["source"]
      version         = "1"

      configuration = {
        ProjectName = "${aws_codebuild_project.tf_codepipeline_cd_build.name}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["test"]
      version         = "1"

      configuration = {
        ProjectName = "${aws_codebuild_project.tf_codepipeline_cd_deploy.name}"
      }
    }
  }
}

resource "aws_codepipeline_webhook" "github_webhook" {
  name            = "tf-aws-cd-pipeline-github"
  authentication  = "GITHUB_HMAC"
  target_action   = "Source"
  target_pipeline = "${aws_codepipeline.tf_aws_cd_pipeline.name}"

  authentication_configuration {
    secret_token = "${data.aws_ssm_parameter.webhooks_secret.value}"
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}

output "webhooks_url" {
    value = "${aws_codepipeline_webhook.github_webhook.url}"
}