resource "spacelift_stack" "spacelift_root" {
  space_id                         = data.spacelift_space.root.id
  name                             = "spacelift-root"
  description                      = "🚀 Spacelift administrative stack"
  repository                       = "homelab"
  branch                           = "main"
  project_root                     = "terraform/spacelift/root"
  additional_project_globs         = ["terraform/environments/**/cell.json"]
  terraform_workflow_tool          = "OPEN_TOFU"
  terraform_version                = "1.12.0"
  autodeploy                       = true
  enable_local_preview             = true
  protect_from_deletion            = false
  terraform_smart_sanitization     = true
  enable_well_known_secret_masking = true

  labels = ["feature:add_plan_pr_comment", "sops-enabled"]
}

data "spacelift_role" "space_admin" {
  slug = "space-admin"
}

resource "spacelift_role_attachment" "spacelift_root_space_admin" {
  space_id = data.spacelift_space.root.id
  stack_id = spacelift_stack.spacelift_root.id
  role_id  = data.spacelift_role.space_admin.id
}

data "spacelift_plugin_template" "sops" {
  plugin_template_id = "sops"
}

resource "spacelift_plugin" "sops" {
  space_id           = data.spacelift_space.root.id
  plugin_template_id = data.spacelift_plugin_template.sops.id
  name               = "sops"
  stack_label        = "sops-enabled"
  parameters = {
    sops_config_path = "/mnt/workspace/source/.sops.yaml"
  }
}

resource "spacelift_context" "sops_decrypt" {
  space_id = data.spacelift_space.root.id
  name     = "sops-decrypt"
  labels   = ["autoattach:sops-enabled"]
}

resource "spacelift_environment_variable" "sops_age_key" {
  context_id       = spacelift_context.sops_decrypt.id
  name             = "SOPS_AGE_KEY"
  value_wo         = var.sops_age_key
  value_wo_version = sha256(var.sops_age_key)
  write_only       = true
}
