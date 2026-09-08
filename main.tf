resource "azurerm_resource_group" "aks" {
  name     = var.group
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "aks" {
  name                = "vnet-${var.cluster_name}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "nodes" {
  name                 = "snet-aks-nodes"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.0.0.0/22"]
}

resource "azurerm_subnet" "apiServer" {
  name                 = "snet-aks-api-server"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.0.4.0/28"]

  delegation {
    name = "aks-api-server"

    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.0.5.0/26"]
}

resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${var.cluster_name}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tags                = var.tags
}

resource "azurerm_role_assignment" "aksNetworkContributor" {
  scope                = azurerm_virtual_network.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
  principal_type       = "ServicePrincipal"
}

module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "0.8.3"

  name      = var.cluster_name
  location  = azurerm_resource_group.aks.location
  parent_id = azurerm_resource_group.aks.id

  kubernetes_version    = "1.36"
  public_network_access = "Disabled"

  managed_identities = {
    user_assigned_resource_ids = [azurerm_user_assigned_identity.aks.id]
  }

  sku = {
    name = "Base"
    tier = "Standard"
  }

  api_server_access_profile = {
    enable_private_cluster             = true
    enable_private_cluster_public_fqdn = false
    enable_vnet_integration            = true
    private_dns_zone                   = "system"
    subnet_id                          = azurerm_subnet.apiServer.id
  }

  network_profile = {
    dns_service_ip      = "10.2.0.10"
    network_dataplane   = "cilium"
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    outbound_type       = "loadBalancer"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.2.0.0/16"
  }

  ingress_profile = {
    gateway_api = {
      installation = "Standard"
    }
    web_app_routing = {
      enabled = true
      gateway_api_implementations = {
        app_routing_istio = {
          mode = "Enabled"
        }
      }
      nginx = {
        default_ingress_controller_type = "None"
      }
    }
  }

  default_agent_pool = {
    name                 = "system"
    count_of             = 3
    vm_size              = "Standard_D4ds_v5"
    availability_zones   = ["1", "2", "3"]
    orchestrator_version = "1.36"
    vnet_subnet_id       = azurerm_subnet.nodes.id
    node_taints          = ["CriticalAddonsOnly=true:NoSchedule"]
    upgrade_settings = {
      max_surge = "33%"
    }
  }

  agent_pools = {
    apps = {
      name                 = "appspool"
      mode                 = "User"
      count_of             = 3
      min_count            = 2
      max_count            = 6
      enable_auto_scaling  = true
      vm_size              = "Standard_D4ds_v5"
      availability_zones   = ["1", "2", "3"]
      orchestrator_version = "1.36"
      vnet_subnet_id       = azurerm_subnet.nodes.id
      node_labels = {
        workload = "apps"
      }
      node_taints = ["workload=apps:NoSchedule"]
      upgrade_settings = {
        max_surge = "33%"
      }
    }
  }

  enable_rbac = true
  aad_profile = {
    managed           = true
    enable_azure_rbac = true
  }

  tags = var.tags

  depends_on = [azurerm_role_assignment.aksNetworkContributor]
}

resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-${var.cluster_name}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_bastion_host" "aks" {
  name                = "bas-${var.cluster_name}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "Standard"
  tunneling_enabled   = true
  ip_connect_enabled  = true
  zones               = ["1", "2", "3"]
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}