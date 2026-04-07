# DataMammoth Terraform — Basic Server Example
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

provider "datamammoth" {
  # API key can also be set via DM_API_KEY env var
  # api_key = "dm_live_..."
}

# Look up available zones
data "datamammoth_zones" "all" {}

# Look up available images in the first zone
data "datamammoth_images" "ubuntu" {
  zone_id  = data.datamammoth_zones.all.zones[0].id
  os_family = "ubuntu"
}

# Look up a product / plan
data "datamammoth_products" "vps" {
  type = "vps"
}

# Create a single VPS server
resource "datamammoth_server" "web" {
  product_id = data.datamammoth_products.vps.products[0].id
  zone_id    = data.datamammoth_zones.all.zones[0].id
  image_id   = data.datamammoth_images.ubuntu.images[0].id
  hostname   = "web-1.example.com"
  label      = "Web Server"

  # Optional: SSH key for passwordless access
  # ssh_key_ids = ["key_abc123"]
}

output "server_id" {
  value = datamammoth_server.web.id
}

output "server_ip" {
  value = datamammoth_server.web.ip_address
}

output "server_ipv6" {
  value = datamammoth_server.web.ipv6_address
}

output "server_status" {
  value = datamammoth_server.web.status
}
