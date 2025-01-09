variable "prefix"{
   description = "prefix used for all resources"
}

variable "location" {
  description = "The location of the resources"
  type        = string
  default     = "West US"
}

variable "resource_group_name" {
  type        = string
  description = "resource group name"
  default     = "Azuredevops"
}


variable "vm_count"{
  default = 2
  description = "Number of virtual machines to be created"
  validation {
    condition = var.vm_count >= 2 && var.vm_count <= 5
    error_message = "The number of virtual machines must be between 2 and 5"
  }

}