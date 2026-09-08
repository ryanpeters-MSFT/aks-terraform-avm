$group = terraform output -raw group
$cluster = terraform output -raw cluster_name
$userId = az ad signed-in-user show --query id -o tsv
$clusterId = az aks show -g $group -n $cluster --query id -o tsv

# grant permission to download user credentials
az role assignment create --assignee-object-id $userId --assignee-principal-type User --role "Azure Kubernetes Service Cluster User Role" --scope $clusterId

# grant cluster-admin authorization through Azure RBAC for Kubernetes
az role assignment create --assignee-object-id $userId --assignee-principal-type User --role "Azure Kubernetes Service RBAC Cluster Admin" --scope $clusterId

# retrieve user credentials and use the current Azure CLI login for authentication
az aks get-credentials -g $group -n $cluster --overwrite-existing
kubelogin convert-kubeconfig -l azurecli

Write-Host "Cluster-admin access and Azure CLI authentication configured. Allow several minutes for RBAC propagation, then run .\connect.ps1."