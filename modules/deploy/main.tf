module "rev-11" {
  source = "./revision"

  revision_path            = "${path.module}/files/v1"
  proxy_version            = "2.6.6"
  backend_version          = "5.2.12"
  monitoring_agent_version = "1.0.6"

  bucket_name   = "fa-internal-revisions2"
  object_prefix = "v1/"
}

output "revision_url" {
    value = module.rev-11.revision_url
}