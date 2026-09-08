output "group" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = module.aks.name
}

output "cluster_id" {
  description = "Resource ID of the AKS cluster."
  value       = module.aks.resource_id
}

output "private_fqdn" {
  description = "Private FQDN of the AKS API server."
  value       = module.aks.private_fqdn
}

output "bastion_id" {
  description = "Resource ID of the Azure Bastion host used by az aks bastion."
  value       = azurerm_bastion_host.this.id
}