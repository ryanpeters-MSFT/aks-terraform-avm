variable "location" {
  description = "Azure region in which to deploy the resources."
  type        = string
  default     = "centralus"
}

variable "group" {
  description = "Name of the resource group."
  type        = string
  default     = "rg-aks-terraform-avm"
}

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
  default     = "aksterraformavm"
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default = {
    scenario = "aks-terraform-avm"
  }
}