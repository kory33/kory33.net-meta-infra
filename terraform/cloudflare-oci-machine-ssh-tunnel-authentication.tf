resource "cloudflare_workers_kv_namespace" "oci_machine_ssh_tunnel_authentication_kv" {
  account_id = cloudflare_zone.main_zone.account_id
  title      = "oci-machine-ssh-tunnel-authentication-kv"
}

resource "cloudflare_worker_script" "oci_machine_ssh_tunnel_authentication" {
  account_id = cloudflare_zone.main_zone.account_id
  name       = "oci-machine-ssh-tunnel-authentication"
  content    = "console.log(\"1\")"

  kv_namespace_binding {
    # The script expects the variable KV to refer to a cloudflare KV interface
    name         = "KV"
    namespace_id = cloudflare_workers_kv_namespace.oci_machine_ssh_tunnel_authentication_kv.id
  }
}

locals {
  oci_machine_ssh_tunnel_authentication_eval_url = "https://${cloudflare_worker_script.oci_machine_ssh_tunnel_authentication}.${local.worker_subdomain}/*"
}

resource "cloudflare_worker_route" "my_route" {
  zone_id     = cloudflare_zone.main_zone.id
  pattern     = local.oci_machine_ssh_tunnel_authentication_eval_url
  script_name = cloudflare_worker_script.oci_machine_ssh_tunnel_authentication.name
}
