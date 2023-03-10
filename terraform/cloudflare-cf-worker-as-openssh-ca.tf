locals {
  cf_worker_as_ca_release_base_url = "https://github.com/kory33/cf-worker-as-openssh-ca/releases/download"

  cf_worker_as_openssh_ca__signer_tag             = "signer-v0.1.3"
  cf_worker_as_openssh_ca__signer_script_url      = "${local.cf_worker_as_ca_release_base_url}/${local.cf_worker_as_openssh_ca__signer_tag}/index.service.js"
  cf_worker_as_openssh_ca__signer_wasm_base64_url = "${local.cf_worker_as_ca_release_base_url}/${local.cf_worker_as_openssh_ca__signer_tag}/signer_internal_crypto_bg.wasm-base64.txt"

  cf_worker_as_openssh_ca__authenticator_tag        = "authenticator-remote-jwt-v0.2.0"
  cf_worker_as_openssh_ca__authenticator_script_url = "${local.cf_worker_as_ca_release_base_url}/${local.cf_worker_as_openssh_ca__authenticator_tag}/index.service.js"
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
  name       = "cf-worker-as-openssh-ca--authenticator"
  content    = data.http.cf_worker_as_openssh_ca__authenticator_script.response_body

  plain_text_binding {
    name = "JWKS_DISTRIBUTION_URL"
    text = "https://token.actions.githubusercontent.com/.well-known/jwks"
  }

  plain_text_binding {
    name = "JWT_CLAIM_EXPECTATION_JSON"
    text = "{}"
  }

  plain_text_binding {
    name = "PRINCIPAL_NAME_TO_AUTHORIZE"
    text = "authorized_by_cf_worker"
  }
}

resource "cloudflare_workers_kv_namespace" "cf_worker_as_openssh_ca__signer" {
  account_id = data.cloudflare_zone.main_zone.account_id
  title      = "cf-worker-as-openssh-ca--signer-kv"
}

resource "cloudflare_worker_script" "cf_worker_as_openssh_ca__signer" {
  account_id = data.cloudflare_zone.main_zone.account_id
  name       = "cf-worker-as-openssh-ca--signer"
  content    = data.http.cf_worker_as_openssh_ca__signer_script.response_body

  kv_namespace_binding {
    # https://github.com/kory33/cf-worker-as-openssh-ca/blob/97825e04a4b6e1035f57f960e7ef811e74a6211c/signer/src/cloudflare/index.service.ts#L19
    name         = "SIGNING_KEY_PAIR_NAMESPACE"
    namespace_id = cloudflare_workers_kv_namespace.cf_worker_as_openssh_ca__signer.id
  }

  service_binding {
    # https://github.com/kory33/cf-worker-as-openssh-ca/blob/97825e04a4b6e1035f57f960e7ef811e74a6211c/signer/src/cloudflare/index.service.ts#L29
    environment = "production"
    name        = "AUTHENTICATOR_SERVICE"
    service     = cloudflare_worker_script.cf_worker_as_openssh_ca__authenticator.name
  }

  webassembly_binding {
    # https://github.com/kory33/cf-worker-as-openssh-ca/blob/97825e04a4b6e1035f57f960e7ef811e74a6211c/signer/src/cloudflare/index.service.ts#L44
    name   = "INTERNAL_CRYPTO_WASM_MODULE"
    module = data.http.cf_worker_as_openssh_ca__signer_wasm_base64.response_body
  }
}

resource "cloudflare_worker_route" "cf_worker_as_openssh_ca__signer" {
  zone_id     = data.cloudflare_zone.main_zone.id
  pattern     = "cf-worker-as-openssh-ca--signer.${local.cloudflare_main_zone}/*"
  script_name = cloudflare_worker_script.cf_worker_as_openssh_ca__signer.name
}

# Add a proxied CNAME record that points to a dummy domain.
#
# When a request comes from the internet, the request goes through
# Cloudflare's traffic sequence (since the CNAME record is proxied),
# and it never goes past Workers (provided what we have bound cf-worker-as-openssh-ca's signer).
# It therefore does not really matter what the domain this CNAME record points to.
resource "cloudflare_record" "cf_worker_as_openssh_ca__signer" {
  zone_id = data.cloudflare_zone.main_zone.id
  name    = "cf-worker-as-openssh-ca--signer.${local.cloudflare_main_zone}"
  value   = "dummy-host.${local.cloudflare_main_zone}"
  type    = "CNAME"
  proxied = true
}
