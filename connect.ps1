$group = terraform output -raw group
$cluster = terraform output -raw cluster_name
$bastionId = terraform output -raw bastion_id
$kubeconfig = Join-Path $HOME ".kube\config"

Write-Host "Opening a child PowerShell with the Azure CLI-authenticated kubeconfig. Run kubectl there; exit closes the tunnel."
az aks bastion tunnel -g $group -n $cluster --bastion $bastionId --kubeconfig-path $kubeconfig --yes