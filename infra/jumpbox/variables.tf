variable "location" {
  type    = string
  default = "eastus2"
}

variable "resource_group_name" {
  type    = string
  default = "cloudguard-rg"
}

variable "vm_size" {
  type    = string
  default = "Standard_D2als_v7" # ~$0.042/hr; deallocate when idle
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "YOUR public IP in CIDR form, e.g. 203.0.113.5/32. NEVER 0.0.0.0/0."
  # Find yours with:  curl -s ifconfig.me
}
