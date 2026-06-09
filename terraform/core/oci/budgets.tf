resource "oci_budget_budget" "default" {
  display_name                          = "Default"
  amount                                = "1"
  compartment_id                        = var.oci_tenancy_ocid
  reset_period                          = "MONTHLY"
  budget_processing_period_start_offset = "1"
  target_type                           = "COMPARTMENT"
  targets                               = [var.oci_tenancy_ocid]
}

data "oci_identity_user" "user" {
  user_id = var.oci_user_ocid
}

resource "oci_budget_alert_rule" "default" {
  budget_id      = oci_budget_budget.default.id
  threshold      = "100"
  threshold_type = "PERCENTAGE"
  type           = "ACTUAL"
  message        = "100% of budget exceeded"
  recipients     = data.oci_identity_user.user.email
}
