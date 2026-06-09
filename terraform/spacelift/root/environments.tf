locals {
  dirs = [
    for f in fileset("${path.module}/../../environments", "*/*/*/cell.json") : dirname(f)
    if try(jsondecode(file("${path.module}/../../environments/${f}")).spacelift.managed, false)
  ]

  cells = {
    for dir in local.dirs : dir => {
      environment = split("/", dir)[0]
      region      = split("/", dir)[1]
      name        = split("/", dir)[2]
      id          = "${split("/", dir)[2]}.${split("/", dir)[1]}.${split("/", dir)[0]}"
    }
  }
}

resource "spacelift_stack" "cell" {
  for_each = local.cells

  space_id                         = data.spacelift_space.root.id
  name                             = each.value.id
  description                      = "🌳 Cell [${each.value.id}]"
  repository                       = "homelab"
  branch                           = "main"
  project_root                     = "terraform/environments/${each.key}"
  terraform_workflow_tool          = "OPEN_TOFU"
  terraform_version                = "1.12.1"
  autodeploy                       = true
  enable_local_preview             = true
  protect_from_deletion            = true
  terraform_smart_sanitization     = true
  enable_well_known_secret_masking = true

  labels = [
    "feature:add_plan_pr_comment",
    "folder:${each.value.environment}/${each.value.region}",
    "terraform-provider-oci",
    "terraform-provider-cloudflare",
    "sops-enabled",
    "ssh-enabled",
    "environment:${each.value.environment}",
    "region:${each.value.region}",
  ]
}

resource "spacelift_stack_dependency" "cell_oci" {
  for_each = local.cells

  stack_id            = spacelift_stack.cell[each.key].id
  depends_on_stack_id = spacelift_stack.oci.id
}

resource "spacelift_stack_dependency_reference" "cell_compartment_ids" {
  for_each = local.cells

  stack_dependency_id = spacelift_stack_dependency.cell_oci[each.key].id
  output_name         = "cell_compartment_ids"
  input_name          = "TF_VAR_cell_compartment_ids"
}

resource "spacelift_stack_dependency" "cell_cloudflare" {
  for_each = local.cells

  stack_id            = spacelift_stack.cell[each.key].id
  depends_on_stack_id = spacelift_stack.cloudflare.id
}

resource "spacelift_stack_dependency_reference" "cell_cloudflare_zone_id" {
  for_each = local.cells

  stack_dependency_id = spacelift_stack_dependency.cell_cloudflare[each.key].id
  output_name         = "jaceystan_com_zone_id"
  input_name          = "TF_VAR_cloudflare_zone_id"
}

resource "spacelift_stack_dependency_reference" "cell_base_domain_external" {
  for_each = local.cells

  stack_dependency_id = spacelift_stack_dependency.cell_cloudflare[each.key].id
  output_name         = "jaceystan_com_${each.value.environment}_domain"
  input_name          = "TF_VAR_base_domain_external"
}

resource "spacelift_stack_dependency_reference" "cell_base_domain_internal" {
  for_each = local.cells

  stack_dependency_id = spacelift_stack_dependency.cell_cloudflare[each.key].id
  output_name         = "jaceystan_com_${each.value.environment}_homelab_domain"
  input_name          = "TF_VAR_base_domain_internal"
}

resource "spacelift_environment_variable" "cell_region" {
  for_each = local.cells

  stack_id   = spacelift_stack.cell[each.key].id
  name       = "TF_VAR_oci_region"
  value      = each.value.region
  write_only = false
}

resource "spacelift_environment_variable" "cell_environment" {
  for_each = local.cells

  stack_id   = spacelift_stack.cell[each.key].id
  name       = "TF_VAR_cell_environment"
  value      = each.value.environment
  write_only = false
}

resource "spacelift_environment_variable" "cell_name" {
  for_each = local.cells

  stack_id   = spacelift_stack.cell[each.key].id
  name       = "TF_VAR_cell_name"
  value      = each.value.name
  write_only = false
}

resource "spacelift_environment_variable" "cell_id" {
  for_each = local.cells

  stack_id   = spacelift_stack.cell[each.key].id
  name       = "TF_VAR_cell_id"
  value      = each.value.id
  write_only = false
}

resource "spacelift_context" "ssh_enabled" {
  space_id = data.spacelift_space.root.id
  name     = "ssh-enabled"

  labels = ["autoattach:ssh-enabled"]
}

resource "spacelift_environment_variable" "compute_ssh_public_key" {
  context_id = spacelift_context.ssh_enabled.id
  name       = "TF_VAR_compute_ssh_public_key"
  value      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINesmGfgWCNNkBYJc1QEKA1KyAh5hjIDETeedinSWOVR"
  write_only = false
}
