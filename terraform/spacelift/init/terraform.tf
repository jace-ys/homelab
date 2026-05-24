terraform {
  required_version = "~> 1.12"

  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "~> 1.49"
    }
  }
}

provider "spacelift" {
  api_key_endpoint = "https://jace-ys.app.spacelift.io"
  api_key_id       = "01KRRVTGGETX67C7RPAWZ7QCDX"
}

data "spacelift_space" "root" {
  space_id = "root"
}
