variable "source_file" {
  default = "./../app/src.zip"
}

variable "region" {
  default = "ap-southeast-2"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "./../../app"
  output_path = "${var.source_file}"
}

data "aws_caller_identity" "current" {}

resource "aws_api_gateway_rest_api" "test_node_api" {
  name        = "TerraformCodePipelineCD"
  description = "Test Code Pipeline"
}

module "tf_codepipeline_cd" {
  source        = "github.com/mtranter/terraform-lambda-api-gateway//module"
  source_file   = "${data.archive_file.lambda.output_path}"
  function_name = "tf-codepipeline-cd"
  runtime       = "nodejs8.10"
  handler       = "src/index.handler"
  stage_name    = "prod"
  account_id    = "${data.aws_caller_identity.current.account_id}"
  rest_api_id   = "${aws_api_gateway_rest_api.test_node_api.id}"
  parent_id     = "${aws_api_gateway_rest_api.test_node_api.root_resource_id}"
  http_method   = "GET"
  region        = "${var.region}"
}

output "invoke_url" {
  value = "${module.tf_codepipeline_cd.aws_api_gateway_deployment_invoke_url}"
}