resource "cloudflare_workers_kv_namespace" "oci_machine_ssh_tunnel_authentication_kv" {
  cloudflare_account_id = data.cloudflare_zone.cloudflare_main_zone.cloudflare_account_id
  title                 = "oci-machine-ssh-tunnel-authentication-kv"
}

resource "cloudflare_worker_script" "oci_machine_ssh_tunnel_authentication" {
  cloudflare_account_id = data.cloudflare_zone.cloudflare_main_zone.cloudflare_account_id
  name                  = "oci-machine-ssh-tunnel-authentication"
  content               = file("../oci-machine-ssh-tunnel-authentication/index.js")

  kv_namespace_binding {
    # The script expects the variable KV to refer to a cloudflare KV interface
    name         = "KV"
    namespace_id = cloudflare_workers_kv_namespace.oci_machine_ssh_tunnel_authentication_kv.id
  }

  plain_text_binding {
    name = "DEBUG"
    text = "truethy"
  }

  plain_text_binding {
    name = "TEAM_DOMAIN"
    text = local.cloudflare_team_domain
  }
}

locals {
  oci_machine_ssh_tunnel_authentication_eval_url = "https://${cloudflare_worker_script.oci_machine_ssh_tunnel_authentication.name}.${local.cloudflare_worker_subdomain}/*"
}
