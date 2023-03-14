data "oci_identity_tenancy" "root_tenancy" {
  tenancy_id = var.oci_tenancy_ocid
}

# the compartment that we manage through Terraform
data "oci_identity_compartments" "terraform_managed_compartment" {
  compartment_id = data.oci_identity_tenancy.root_tenancy.id
  name           = local.oci_managed_compartment_name

  lifecycle {
    postcondition {
      condition     = length(self.compartments) == 1
      error_message = "No compartment with the name ${local.oci_managed_compartment_name} found."
    }
  }
}

locals {
  terraform_managed_compartment = data.oci_identity_compartments.terraform_managed_compartment.compartments[0]
}

data "oci_identity_availability_domains" "all" {
  compartment_id = data.oci_identity_tenancy.root_tenancy.id

  lifecycle {
    postcondition {
      condition     = length(self.availability_domains) > 0
      error_message = "No availability domain in ${self.compartment_id} found."
    }
  }
}

locals {
  first_availability_domain = data.oci_identity_availability_domains.all.availability_domains[0]
}
