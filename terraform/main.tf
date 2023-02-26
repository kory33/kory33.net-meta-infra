terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4"
    }
    oci = {
      source  = "hashicorp/oci"
      version = "~> 4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
  }

  cloud {
    organization = "kory33"

    workspaces {
      name = "seichi_infra"
    }
  }
}

variable "cloudflare_api_token" {
  description = "API token used for Cloudflare API authentication"
  type        = string
  sensitive   = true
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

variable "oci_tenancy_ocid" {
  description = "OCID of the OCI tenancy on which Terraform manages resources"
  type        = string
  sensitive   = false
}

variable "oci_user_ocid" {
  description = "OCID of the OCI User through which Terraform manages resources"
  type        = string
  sensitive   = false
}

variable "oci_user_private_key" {
  description = "OCI User's private key, whose public counterpart is manually registered to OCI"
  type        = string
  sensitive   = true
}

variable "oci_user_public_key_fingerprint" {
  description = "OCI User's public key that is manually registered to OCI"
  type        = string
  sensitive   = false
}

variable "oci_region" {
  description = "Region of the tenancy"
  type        = string
  sensitive   = false
}

provider "oci" {
  tenancy_ocid = var.oci_tenancy_ocid
  user_ocid    = var.oci_user_ocid
  private_key  = var.oci_user_private_key
  fingerprint  = var.oci_user_public_key_fingerprint
  region       = var.oci_region
}
