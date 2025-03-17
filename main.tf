terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Groupe de ressources
resource "azurerm_resource_group" "CR460_test" {
  name     = "terraform-cloud-test-rg"
  location = "Canada Central"
  tags = {
    CreatedBy = "Roger_nguessi"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "CR460_vnet" {
  name                = "terraform-cr460-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.CR460_test.location
  resource_group_name = azurerm_resource_group.CR460_test.name
  tags = {
    CreatedBy = "Roger_nguessi"
  }
}

# Sous-réseau
resource "azurerm_subnet" "subnet1" {
  name                 = "subnet-terraform"
  resource_group_name  = azurerm_resource_group.CR460_test.name
  virtual_network_name = azurerm_virtual_network.CR460_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# IP publique
resource "azurerm_public_ip" "CR460_pip" {
  name                = "cr460-vm-pip"
  location            = azurerm_resource_group.CR460_test.location
  resource_group_name = azurerm_resource_group.CR460_test.name
  allocation_method   = "Dynamic"
  tags = {
    CreatedBy = "Roger_nguessi"
  }
}

# Interface réseau
resource "azurerm_network_interface" "CR460_nic" {
  name                = "cr460-vm-nic"
  location            = azurerm_resource_group.CR460_test.location
  resource_group_name = azurerm_resource_group.CR460_test.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    public_ip_address_id          = azurerm_public_ip.CR460_pip.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    CreatedBy = "Roger_nguessi"
  }
}

# Machine virtuelle Linux
resource "azurerm_linux_virtual_machine" "vm_linux" {
  name                = "cr460-vm"
  resource_group_name = azurerm_resource_group.CR460_test.name
  location            = azurerm_resource_group.CR460_test.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.CR460_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("${path.module}/id_rsa.pub")
  }
  tags = {
    CreatedBy = "Roger_nguessi"
  }
}

# Container Instance avec NGINX
resource "azurerm_container_group" "nginx_container" {
  name                = "terraform-cloud-docker-test"
  location            = azurerm_resource_group.CR460_test.location
  resource_group_name = azurerm_resource_group.CR460_test.name
  ip_address_type     = "Public"
  dns_name_label      = "terraform-docker-container"
  os_type             = "Linux"

  container {
    name   = "nginx-container"
    image  = "nginx:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }
  tags = {
    CreatedBy = "Roger_nguessi"
  }
}
