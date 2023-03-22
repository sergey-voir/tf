provider "aws" {
  region = "us-west-1"
}

locals {
  compose_file                   = file("${var.revision_path}/docker-compose.yml")
  docker_compose_template_params = {
    "{ proxy_version }"            = var.proxy_version
    "{ backend_version }"          = var.backend_version
    "{ monitoring_agent_version }" = var.monitoring_agent_version
  }
  module_id   = random_id.id.hex

  dep_params  = flatten([for k, v in local.docker_compose_template_params : regexall(k, local.compose_file)])
  params_sha1 = join("", [for p in local.dep_params : sha1(lookup(local.docker_compose_template_params, p))])

  files_list  = fileset("${var.revision_path}/", "*")
  files_sha1  = join("", [for f in local.files_list : filesha1("${var.revision_path}/${f}")])

  all_sha1    = sha1(format("%s-%s-%s", local.module_id, local.files_sha1, local.params_sha1))
  obj_id      = substr(sha1(local.all_sha1), 0, 8)
}

resource "random_id" "id" {
	  byte_length = 8
}

data "template_file" "docker_compose" {
  for_each = local.files_list
  template = file("${var.revision_path}/${each.value}")

  vars = {
    proxy_version            = var.proxy_version
    backend_version          = var.backend_version
    monitoring_agent_version = var.monitoring_agent_version
  }
}

data "archive_file" "zip" {
  type        = "zip"
  output_path = "${path.module}/${local.obj_id}.zip"
  dynamic "source" {
    for_each = data.template_file.docker_compose
    content {
      content  = source.value.rendered
      filename = source.key
    }
  }
}

resource "aws_s3_bucket" "rev_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_object" "rev_obj" {
  bucket = aws_s3_bucket.rev_bucket.id
  key    = "${var.object_prefix}${local.obj_id}.zip"
  source = data.archive_file.zip.output_path
}
