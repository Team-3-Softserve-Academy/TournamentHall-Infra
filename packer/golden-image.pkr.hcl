packer {
  required_plugins {
    virtualbox = {
      version = "~> 1"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

source "virtualbox-iso" "base-image" {
  guest_os_type        = "Ubuntu_64"
  iso_url              = "https://releases.ubuntu.com/26.04/ubuntu-26.04-live-server-amd64.iso"
  iso_checksum         = "dec49008a71f6098d0bcfc822021f4d042d5f2db279e4d75bdd981304f1ca5d9"
  ssh_username         = "base"
  ssh_private_key_file = "~/.ssh/packer_key"
  ssh_timeout          = "2h"
  shutdown_command     = "echo 'base' | sudo -S shutdown -P now"
  // Set 'headless' to false to launch virtual box and see configuring progress
  headless         = "true"
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--memory", "4096"],
    ["modifyvm", "{{.Name}}", "--cpus", "2"],
    ["modifyvm", "{{.Name}}", "--vram", "32"],
  ]
  http_directory = "packer/http/golden-image"
  boot_command = [
    "c",
    "linux /casper/vmlinuz --- autoinstall ds='nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/'<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]
}

build {
  name = "golden-image"
  sources = [
    "sources.virtualbox-iso.base-image"
  ]
}
