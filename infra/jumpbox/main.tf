# Azure requires a dependency chain for a reachable VM:
# Resource Group -> VNet -> Subnet -> (Public IP + NSG) -> NIC -> VM
# Terraform figures out this order automatically from the references between
# resources; you don't declare order, you declare relationships
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# The private network your resources live in
resource "azurerm_virtual_network" "main" {
  name                = "cloudguard-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Network config for the jump-box
resource "azurerm_subnet" "jumpbox" {
  name                 = "jumpbox-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# A stable public IP so you can SSH in from your machine
resource "azurerm_public_ip" "jumpbox" {
  name                = "jumpbox-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Firewall: (Port 22) ONLY from your IP. Everything else is denied by
# Azure's default rules, this single rule is your main attack-surface control
resource "azurerm_network_security_group" "jumpbox" {
  name                = "jumpbox-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSSHFromMyIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_cidr
    destination_address_prefix = "*"
  }
}

# The virtual network card that attaches the VM to the subnet + public IP
resource "azurerm_network_interface" "jumpbox" {
  name                = "jumpbox-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jumpbox.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox.id
  }
}

# Binds the firewall rules to the NIC
resource "azurerm_network_interface_security_group_association" "jumpbox" {
  network_interface_id      = azurerm_network_interface.jumpbox.id
  network_security_group_id = azurerm_network_security_group.jumpbox.id
}

# The VM itself, SSH-key auth only, no password login
resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                  = "cloudguard-jumpbox"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.jumpbox.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Ubuntu 22.04 LTS (Jammy), bump to 24.04 by switching offer to
  # "ubuntu-24_04-lts"/sku "server" once you've confirmed availability
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Installs docker, kubectl, az CLI, and terraform on first boot so the
  # box is a ready-to-use workstation, reproducible = principal-SRE hygiene
  custom_data = base64encode(file("${path.module}/cloud-init.yaml"))
}
