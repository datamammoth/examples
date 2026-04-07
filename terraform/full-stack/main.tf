# DataMammoth Terraform — Full Stack Example
#
# Provisions a web server, database server, and configures firewall + webhooks.
#
# Usage:
#   export DM_API_KEY="dm_live_..."
#   terraform init
#   terraform plan
#   terraform apply

terraform {
  required_providers {
    datamammoth = {
      source  = "datamammoth/datamammoth"
      version = "~> 0.1"
    }
  }
}

provider "datamammoth" {}

variable "environment" {
  description = "Environment name (prod, staging, dev)"
  type        = string
  default     = "staging"
}

variable "webhook_url" {
  description = "URL to receive webhook notifications"
  type        = string
  default     = "https://hooks.example.com/datamammoth"
}

# ── Data Sources ─────────────────────────────────────────────────

data "datamammoth_zones" "eu" {
  region = "EU"
}

data "datamammoth_images" "ubuntu" {
  zone_id  = data.datamammoth_zones.eu.zones[0].id
  os_family = "ubuntu"
}

data "datamammoth_products" "vps_small" {
  type       = "vps"
  min_cpu    = 2
  min_ram_gb = 4
}

data "datamammoth_products" "vps_large" {
  type       = "vps"
  min_cpu    = 4
  min_ram_gb = 16
}

# ── Web Servers ──────────────────────────────────────────────────

resource "datamammoth_server" "web" {
  count = var.environment == "prod" ? 2 : 1

  product_id = data.datamammoth_products.vps_small.products[0].id
  zone_id    = data.datamammoth_zones.eu.zones[0].id
  image_id   = data.datamammoth_images.ubuntu.images[0].id
  hostname   = "web-${count.index + 1}.${var.environment}.example.com"
  label      = "Web ${count.index + 1} (${var.environment})"

  lifecycle {
    create_before_destroy = true
  }
}

# ── Database Server ──────────────────────────────────────────────

resource "datamammoth_server" "db" {
  product_id = data.datamammoth_products.vps_large.products[0].id
  zone_id    = data.datamammoth_zones.eu.zones[0].id
  image_id   = data.datamammoth_images.ubuntu.images[0].id
  hostname   = "db-1.${var.environment}.example.com"
  label      = "Database (${var.environment})"
}

# ── Firewall Rules ───────────────────────────────────────────────

resource "datamammoth_firewall" "web" {
  count     = length(datamammoth_server.web)
  server_id = datamammoth_server.web[count.index].id

  rule {
    protocol = "tcp"
    port     = "22"
    source   = "0.0.0.0/0"
    action   = "allow"
    comment  = "SSH"
  }

  rule {
    protocol = "tcp"
    port     = "80"
    source   = "0.0.0.0/0"
    action   = "allow"
    comment  = "HTTP"
  }

  rule {
    protocol = "tcp"
    port     = "443"
    source   = "0.0.0.0/0"
    action   = "allow"
    comment  = "HTTPS"
  }
}

resource "datamammoth_firewall" "db" {
  server_id = datamammoth_server.db.id

  rule {
    protocol = "tcp"
    port     = "22"
    source   = "0.0.0.0/0"
    action   = "allow"
    comment  = "SSH"
  }

  # Only allow DB access from web servers
  dynamic "rule" {
    for_each = datamammoth_server.web
    content {
      protocol = "tcp"
      port     = "5432"
      source   = "${rule.value.ip_address}/32"
      action   = "allow"
      comment  = "PostgreSQL from ${rule.value.hostname}"
    }
  }
}

# ── Snapshots ────────────────────────────────────────────────────

resource "datamammoth_snapshot" "db_backup" {
  server_id = datamammoth_server.db.id
  name      = "db-backup-${var.environment}"
}

# ── Webhooks ─────────────────────────────────────────────────────

resource "datamammoth_webhook" "notifications" {
  url    = var.webhook_url
  active = true

  events = [
    "server.created",
    "server.terminated",
    "server.action.completed",
    "invoice.paid",
    "invoice.overdue",
  ]
}

# ── Outputs ──────────────────────────────────────────────────────

output "web_ips" {
  value = datamammoth_server.web[*].ip_address
}

output "db_ip" {
  value = datamammoth_server.db.ip_address
}

output "web_hostnames" {
  value = datamammoth_server.web[*].hostname
}

output "snapshot_id" {
  value = datamammoth_snapshot.db_backup.id
}
