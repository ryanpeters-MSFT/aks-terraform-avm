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
- Two-node `testpool` user pool using the AKS `VirtualMachines` agent pool type and a manual scale profile
- Standard Azure Bastion with native client tunneling and no jumpbox
- A user-assigned AKS control-plane identity with Network Contributor access to the VNet

## Prerequisites

- Terraform 1.11 or later
- Azure CLI signed in to the target subscription
- Permission to create the resources and role assignment
- Sufficient Central US quota for up to eleven `Standard_D4ds_v5` VMs during normal autoscaling, plus temporary upgrade surge capacity
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

Prerequisites for local access are Azure CLI 2.85.0 or later, the `aks-preview` extension, `kubectl`, and `kubelogin`. Install or update the extension if needed:

```powershell
az extension add -n aks-preview --upgrade
```

Grant the current signed-in Microsoft Entra user permission to retrieve AKS user credentials and cluster-admin authorization through Azure RBAC for Kubernetes. The script also retrieves the user kubeconfig and runs `kubelogin convert-kubeconfig -l azurecli` so Kubernetes authentication uses the current Azure CLI session instead of device-code login:

```powershell
./access.ps1
```

Creating role assignments requires Owner or User Access Administrator permission at the cluster scope or above. Allow several minutes for new assignments to propagate.

Start the AKS Bastion tunnel:

```powershell
./connect.ps1
```

The connection script reads the resource group, cluster name, and Bastion resource ID from Terraform outputs. It opens a child PowerShell using the Azure CLI-authenticated kubeconfig configured for the tunnel. Run `kubectl` inside that shell, then enter `exit` to close the tunnel:

```powershell
# test connectivity
kubectl get nodes -o wide
```

## References

- [AKS Azure Verified Module](https://github.com/Azure/terraform-azurerm-avm-res-containerservice-managedcluster)
- [Module Catalog](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/)
- [`avm-res-containerservice-managedcluster`](https://registry.terraform.io/modules/Azure/avm-res-containerservice-managedcluster/azurerm/latest)
- [API Server VNet Integration](https://learn.microsoft.com/azure/aks/api-server-vnet-integration)
- [Azure CNI powered by Cilium](https://learn.microsoft.com/azure/aks/azure-cni-powered-by-cilium)
- [Connect to a private AKS cluster with Azure Bastion](https://learn.microsoft.com/azure/bastion/bastion-connect-to-aks-private-cluster)
