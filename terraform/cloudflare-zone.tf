resource "cloudflare_zone" "main_zone" {
  account_id = var.cloudflare_account_id
  zone       = local.main_zone
}
