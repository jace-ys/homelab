resource "spacelift_stack" "cloudflare" {
  space_id                         = data.spacelift_space.root.id
  name                             = "cloudflare"
  description                      = "🌐 Cloudflare"
  repository                       = "homelab"
  branch                           = "main"
  project_root                     = "terraform/core/cloudflare"
  terraform_workflow_tool          = "OPEN_TOFU"
  terraform_version                = "1.12.1"
  autodeploy                       = true
  enable_local_preview             = true
  protect_from_deletion            = true
  terraform_smart_sanitization     = true
  enable_well_known_secret_masking = true

  labels = [
    "feature:add_plan_pr_comment",
    "terraform-provider-cloudflare",
    "sops-enabled",
  ]
}

resource "spacelift_stack_dependency" "cloudflare" {
  stack_id            = spacelift_stack.cloudflare.id
  depends_on_stack_id = data.spacelift_stack.spacelift_root.id
}

resource "spacelift_context" "terraform_provider_cloudflare" {
  space_id = data.spacelift_space.root.id
  name     = "terraform-provider-cloudflare"

  labels = ["autoattach:terraform-provider-cloudflare"]
}

resource "spacelift_environment_variable" "terraform_provider_cloudflare" {
  for_each = {
    email = "jaceys.tan@gmail.com"
  }

  context_id = spacelift_context.terraform_provider_cloudflare.id
  name       = "TF_VAR_cloudflare_${each.key}"
  value      = each.value
  write_only = false
}

resource "spacelift_environment_variable" "terraform_provider_cloudflare_secrets" {
  for_each = {
    account_id = local.secrets.cloudflare.account_id
    api_token  = local.secrets.cloudflare.api_token
  }

  context_id       = spacelift_context.terraform_provider_cloudflare.id
  name             = "TF_VAR_cloudflare_${each.key}"
  value_wo         = each.value
  value_wo_version = sha256(each.value)
  write_only       = true
}
