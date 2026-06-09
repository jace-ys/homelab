resource "spacelift_stack" "oci" {
  space_id                         = data.spacelift_space.root.id
  name                             = "oci"
  description                      = "☁️ Oracle Cloud Infrastructure"
  repository                       = "homelab"
  branch                           = "main"
  project_root                     = "terraform/core/oci"
  additional_project_globs         = ["terraform/environments/**/cell.json"]
  terraform_workflow_tool          = "OPEN_TOFU"
  terraform_version                = "1.12.1"
  autodeploy                       = true
  enable_local_preview             = true
  protect_from_deletion            = true
  terraform_smart_sanitization     = true
  enable_well_known_secret_masking = true

  labels = [
    "feature:add_plan_pr_comment",
    "terraform-provider-oci",
    "sops-enabled",
  ]
}

resource "spacelift_stack_dependency" "oci" {
  stack_id            = spacelift_stack.oci.id
  depends_on_stack_id = data.spacelift_stack.spacelift_root.id
}

resource "spacelift_environment_variable" "oci_region" {
  stack_id   = spacelift_stack.oci.id
  name       = "TF_VAR_oci_region"
  value      = "uk-london-1"
  write_only = false
}

resource "spacelift_context" "terraform_provider_oci" {
  space_id = data.spacelift_space.root.id
  name     = "terraform-provider-oci"

  labels = ["autoattach:terraform-provider-oci"]
}

resource "spacelift_mounted_file" "oci_api_key" {
  context_id         = spacelift_context.terraform_provider_oci.id
  relative_path      = ".oci/oci_api_key.pem"
  content_wo         = base64encode(local.secrets.oci["oci_api_key.pem"])
  content_wo_version = sha256(local.secrets.oci["oci_api_key.pem"])
  write_only         = true
}

resource "spacelift_environment_variable" "terraform_provider_oci" {
  for_each = {
    tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaaapg6qcdugjc6ya3cas7ddz2dijh3oqhr2pmfhel2qtmyfir7vfcq"
    user_ocid        = "ocid1.user.oc1..aaaaaaaapafsajfep23hgc2fju6id7q6hydzvc2phzb7sjmp2iqhub57rula"
    fingerprint      = "7c:55:87:8e:c2:ef:75:cd:aa:56:8b:56:8a:35:47:56"
    private_key_path = "/mnt/workspace/${spacelift_mounted_file.oci_api_key.relative_path}"
  }

  context_id = spacelift_context.terraform_provider_oci.id
  name       = "TF_VAR_oci_${each.key}"
  value      = each.value
  write_only = false
}
