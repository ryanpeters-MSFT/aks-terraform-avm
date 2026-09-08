# AKS with the Azure Verified Module

This sample deploys an AKS Standard cluster by using version `0.8.3` of the [AKS Azure Verified Module](https://registry.terraform.io/modules/Azure/avm-res-containerservice-managedcluster/azurerm/0.8.3).

## Deployed configuration

- Resource group `rg-aks-terraform-avm` in `centralus`
- AKS cluster `aksterraformavm` on Kubernetes `1.36`
- Azure CNI Overlay with the Cilium data plane and network policy
- Private API endpoint with API Server VNet Integration
- Application Routing with the managed Gateway API and Istio implementation
- Three-zone, three-node `system` pool tainted `CriticalAddonsOnly=true:NoSchedule`
- Three-zone `appspool` user pool, initially three nodes, autoscaling from two to six, tainted `workload=apps:NoSchedule`
- Standard Azure Bastion with native client tunneling and no jumpbox
- A user-assigned AKS control-plane identity with Network Contributor access to the VNet

## Prerequisites

- Terraform 1.11 or later
- Azure CLI signed in to the target subscription
- Permission to create the resources and role assignment
- Sufficient Central US quota for up to nine `Standard_D4ds_v5` VMs during normal autoscaling, plus temporary upgrade surge capacity
- Azure CLI 2.73.0 or later for API Server VNet Integration workflows

Kubernetes versions and VM SKU capacity vary by subscription and region. Confirm that AKS `1.36` and `Standard_D4ds_v5` are available in Central US before applying.

## Deploy

```powershell
az login
az account set -s <subscription-name-or-id>
$env:ARM_SUBSCRIPTION_ID = az account show --query id -o tsv

terraform init
terraform plan -out main.tfplan
terraform apply main.tfplan
```

## Connect with Azure Bastion

The Bastion deployment uses the Standard SKU with tunneling and IP-based connections enabled. The following native-client workflow reaches the private AKS API directly; it does not deploy or require a jumpbox.

Install or update the Azure CLI `aks-preview` extension if needed (`az aks bastion` requires Azure CLI 2.85.0 or later):

```powershell
az extension add -n aks-preview --upgrade
```

Start the AKS Bastion tunnel. The command opens a subshell with a temporary kubeconfig configured for the tunnel:

```powershell
$group = "rg-aks-terraform-avm"
$cluster = "aksterraformavm"
$bastion = terraform output -raw bastion_id

az aks bastion tunnel -g $group -n $cluster --admin --bastion $bastion
```

Run `kubectl` inside that subshell, then enter `exit` to close the tunnel:

```powershell
kubectl get nodes -o wide
exit
```

The `--admin` option is convenient for this sample. For shared or production environments, assign Microsoft Entra groups appropriate Azure Kubernetes Service RBAC roles and omit `--admin`.

## Destroy

```powershell
terraform destroy
```

## References

- [AKS Azure Verified Module](https://github.com/Azure/terraform-azurerm-avm-res-containerservice-managedcluster)
- [API Server VNet Integration](https://learn.microsoft.com/azure/aks/api-server-vnet-integration)
- [Azure CNI powered by Cilium](https://learn.microsoft.com/azure/aks/azure-cni-powered-by-cilium)
- [Connect to a private AKS cluster with Azure Bastion](https://learn.microsoft.com/azure/bastion/bastion-connect-to-aks-private-cluster)
