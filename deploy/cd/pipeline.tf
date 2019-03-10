resource "aws_s3_bucket" "tf_aws_cd_pipeline" {
  bucket = "tf_aws_cd_pipeline"
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
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
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
      input_artifacts = ["source"]
      version         = "1"

      configuration = {
        ProjectName = "${aws_codebuild_project.tf_codepipeline_cd_build.name}"
      }
    }
  }
}