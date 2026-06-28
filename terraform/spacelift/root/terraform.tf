terraform {
  required_version = "~> 1.12"

  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "~> 1.52"
    }
  }
}

provider "spacelift" {}

data "spacelift_space" "root" {
  space_id = "root"
}

data "spacelift_stack" "spacelift_root" {
  stack_id = "spacelift-root"
}

locals {
  secrets = try(yamldecode(file("${path.module}/data/secrets.yaml")), {})
}
