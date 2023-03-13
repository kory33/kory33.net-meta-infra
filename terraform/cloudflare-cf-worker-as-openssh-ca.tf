locals {
  cf_worker_as_ca_release_base_url = "https://github.com/kory33/cf-worker-as-openssh-ca/releases/download"

  cf_worker_as_openssh_ca__signer_tag             = "signer-v0.1.3"
  cf_worker_as_openssh_ca__signer_script_url      = "${local.cf_worker_as_ca_release_base_url}/${local.cf_worker_as_openssh_ca__signer_tag}/index.service.js"
  cf_worker_as_openssh_ca__signer_wasm_base64_url = "${local.cf_worker_as_ca_release_base_url}/${local.cf_worker_as_openssh_ca__signer_tag}/signer_internal_crypto_bg.wasm-base64.txt"

  cf_worker_as_openssh_ca__authenticator_tag        = "authenticator-remote-jwt-v0.1.0"
  cf_worker_as_openssh_ca__authenticator_script_url = "${local.cf_worker_as_ca_release_base_url}/${local.cf_worker_as_openssh_ca__authenticator_tag}/index.es6.js"
}

data "http" "cf_worker_as_openssh_ca__signer_script" {
  url = local.cf_worker_as_openssh_ca__signer_script_url

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Status code was ${self.status_code}, expected 200."
    }
  }
}

data "http" "cf_worker_as_openssh_ca__signer_wasm_base64" {
  url = local.cf_worker_as_openssh_ca__signer_wasm_base64_url

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Status code was ${self.status_code}, expected 200."
    }
  }
}

data "http" "cf_worker_as_openssh_ca__authenticator_script" {
  url = local.cf_worker_as_openssh_ca__authenticator_script_url

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Status code was ${self.status_code}, expected 200."
    }
  }
}

resource "cloudflare_worker_script" "cf_worker_as_openssh_ca__authenticator" {
  account_id = data.cloudflare_zone.main_zone.account_id
  name       = "cf-worker-as-ca--authenticator"
  content    = data.http.cf_worker_as_openssh_ca__authenticator_script.response_body

  plain_text_binding {
    name = "JWKS_DISTRIBUTION_URL"
    text = "https://token.actions.githubusercontent.com/.well-known/jwks"
  }

  plain_text_binding {
    name = "ETA_TEMPLATE_FOR_PRINCIPALS"
    text = "<% if (true) %>authorized_by_cf_worker<% } %>"
  }
}

resource "cloudflare_workers_kv_namespace" "cf_worker_as_openssh_ca__signer" {
  account_id = data.cloudflare_zone.main_zone.account_id
  title      = "oci-machine-ssh-tunnel-authentication-kv"
}

resource "cloudflare_worker_script" "cf_worker_as_openssh_ca__signer" {
  account_id = data.cloudflare_zone.main_zone.account_id
  name       = "cf-worker-as-ca--signer"
  content    = data.http.cf_worker_as_openssh_ca__signer_script.response_body

  kv_namespace_binding {
    # https://github.com/kory33/cf-worker-as-openssh-ca/blob/97825e04a4b6e1035f57f960e7ef811e74a6211c/signer/src/cloudflare/index.service.ts#L19
    name         = "SIGNING_KEY_PAIR_NAMESPACE"
    namespace_id = cloudflare_workers_kv_namespace.cf_worker_as_openssh_ca__signer.id
  }

  service_binding {
    # https://github.com/kory33/cf-worker-as-openssh-ca/blob/97825e04a4b6e1035f57f960e7ef811e74a6211c/signer/src/cloudflare/index.service.ts#L29
    name    = "AUTHENTICATOR_SERVICE"
    service = cloudflare_worker_script.cf_worker_as_openssh_ca__authenticator.name
  }

  webassembly_binding {
    # https://github.com/kory33/cf-worker-as-openssh-ca/blob/97825e04a4b6e1035f57f960e7ef811e74a6211c/signer/src/cloudflare/index.service.ts#L44
    name   = "INTERNAL_CRYPTO_WASM_MODULE"
    module = data.http.cf_worker_as_openssh_ca__signer_wasm_base64.response_body
  }
}
