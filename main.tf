terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.113.0"
    }
  }
}

provider "azurerm" {
  features {}
}


data "azurerm_image" "packerimage" {
  name                = "PackerImageTest"
  resource_group_name = var.resource_group_name
}

output "image_id" {
  value = data.azurerm_image.packerimage.id
}


# create vnet

resource "azurerm_virtual_network" "udacity_vnet_test" {
  name                = "udacity_vnet_test"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = var.resource_group_name
  location            = var.location
  tags = {
    tagname = "udacity"
  }

}

# create Subnet on the virtual network

resource "azurerm_subnet" "udacity_subnet_test" {
  name                 = "udacity_subnet_test"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.udacity_vnet_test.name
  address_prefixes     = ["10.0.1.0/24"]

}

# network security group

resource "azurerm_network_security_group" "udacity_nsg" {
  name                = "nsg-test"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags = {
    tagname = "udacity"
  }
}

resource "azurerm_network_security_rule" "deny_internet" {
  name                        = "internet-deny-rule"
  priority                    = 400
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.udacity_nsg.name
}

resource "azurerm_network_security_rule" "allow_vnet_inbound" {
  name                        = "allow-vnet-inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.rgName.name
  network_security_group_name = azurerm_network_security_group.udacity_nsg.name
}

resource "azurerm_network_security_rule" "allow_vnet_outbound" {
  name                        = "allow-vnet-outbound"
  priority                    = 300
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.rgName.name
  network_security_group_name = azurerm_network_security_group.udacity_nsg.name
}

resource "azurerm_network_security_rule" "allow_http_lb" {
  name                        = "allow-HTTP-from-LB"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "LoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rgName.name
  network_security_group_name = azurerm_network_security_group.udacity_nsg.name
}



resource "azurerm_network_interface" "udacity_nic" {
  count               = var.vm_count
  name                = "nic-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags = {
    tagname = "udacity"
  }

  ip_configuration {
    name                          = "nic-ipconfig"
    subnet_id                     = azurerm_subnet.udacity_subnet_test.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Public ip

resource "azurerm_public_ip" "udacity_public_ip" {
  name                = "public-ip-test"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
  tags = {
    tagname = "udacity"
  }
}

# Load balancer

resource "azurerm_lb" "udacity_lb" {
  name                = "lb-test"
  location            = var.location
  resource_group_name = var.resource_group_name

  frontend_ip_configuration {
    name                 = "lb-frontend"
    public_ip_address_id = azurerm_public_ip.udacity_public_ip.id
  }
  tags = {
    tagname = "udacity"
  }
}

# Backend pool 

resource "azurerm_lb_backend_address_pool" "udacity_backend_pool" {
  name            = "backend-pool"
  loadbalancer_id = azurerm_lb.udacity_lb.id
}

# virual machine availability set

resource "azurerm_availability_set" "udacity_availability_set" {
  name                = "availability-set"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags = {
    tagname = "udacity"
  }
}

# create vm  
resource "azurerm_virtual_machine" "vm_udacity" {
  count                 = var.vm_count
  name                  = "VM-${count.index}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  availability_set_id   = azurerm_availability_set.udacity_availability_set.id
  network_interface_ids = [azurerm_network_interface.udacity_nic[count.index].id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    id = data.azurerm_image.packerimage.id
  }


 os_profile {
    computer_name  = "VM-${count.index}"
    admin_username = "user"
    admin_password = "Udacity123!"
  } 


  storage_os_disk {
    name              = "VMOSDisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

 

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    project_name = "deployment",
    tagname  = "udacity"
  }
}














