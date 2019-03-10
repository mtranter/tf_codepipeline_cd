terragrunt = {
  remote_state {
    backend = "s3"
    config {
      bucket         = "tf-codepipeline-cd-demo"
      key            = "${path_relative_to_include()}/terraform.tfstate"
      region         = "ap-southeast-2"
      encrypt        = true
      dynamodb_table = "tf-codepipeline-cd-demo-terraform-state-lock"
    }
  }
  terraform { }
}

