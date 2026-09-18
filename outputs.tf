output "group" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.aks.name
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

output "oidc_issuer_url" {
  description = "OIDC issuer URL used by Microsoft Entra Workload ID federated credentials."
  value       = module.aks.oidc_issuer_profile_issuer_url
}

output "workload_identity_client_id" {
  description = "Client ID used to annotate the workloaduser Kubernetes service account."
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "workload_identity_principal_id" {
  description = "Principal ID used to grant the workload identity access to Azure resources."
  value       = azurerm_user_assigned_identity.workload.principal_id
}

output "bastion_id" {
  description = "Resource ID of the Azure Bastion host used by az aks bastion."
  value       = azurerm_bastion_host.aks.id
}

output "acr_name" {
  description = "Name of the Azure Container Registry."
  value       = azurerm_container_registry.aks.name
}

output "acr_login_server" {
  description = "Private login server for the Azure Container Registry."
  value       = azurerm_container_registry.aks.login_server
}