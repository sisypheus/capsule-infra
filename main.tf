terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.35"
    }
  }
}

variable "ssh_key_name" {
  description = "Le nom de la clé SSH à utiliser, configurée dans le projet Hetzner."
  default     = "mbp13"
}

data "hcloud_ssh_key" "default" {
  name = var.ssh_key_name
}

resource "hcloud_network" "private_net" {
  name     = "capsule-private-net"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "private_subnet" {
  network_id   = hcloud_network.private_net.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_server" "control_plane" {
  name        = "control-plane-1"
  server_type = "cpx11"
  image       = "debian-13"
  location    = "hel1"
  ssh_keys    = [data.hcloud_ssh_key.default.id]

  network {
    network_id = hcloud_network.private_net.id
    ip         = "10.0.1.4"
  }
}

resource "hcloud_server" "workers" {
  count       = 2
  name        = "worker-${count.index + 1}"
  server_type = "cpx11"
  image       = "debian-13"
  location    = "hel1"
  ssh_keys    = [data.hcloud_ssh_key.default.id]

  network {
    network_id = hcloud_network.private_net.id
  }
}

output "control_plane_ip" {
  value = hcloud_server.control_plane.ipv4_address
}

output "worker_ips" {
  value = hcloud_server.workers.*.ipv4_address
}