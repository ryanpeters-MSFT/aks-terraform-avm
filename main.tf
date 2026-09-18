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

resource "azurerm_subnet" "privateEndpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.0.5.64/27"]
}

resource "azurerm_network_security_group" "nodes" {
  name                = "nsg-aks-nodes"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tags                = var.tags
}

resource "azurerm_network_security_group" "apiServer" {
  name                = "nsg-aks-api-server"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tags                = var.tags
}

resource "azurerm_network_security_group" "privateEndpoints" {
  name                = "nsg-private-endpoints"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tags                = var.tags
}

resource "azurerm_network_security_group" "bastion" {
  name                = "nsg-bastion"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tags                = var.tags

  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowGatewayManagerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowBastionHostCommunicationInbound"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowSshRdpOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowAzureCloudOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  security_rule {
    name                       = "AllowBastionCommunicationOutbound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowHttpOutbound"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

resource "azurerm_subnet_network_security_group_association" "nodes" {
  subnet_id                 = azurerm_subnet.nodes.id
  network_security_group_id = azurerm_network_security_group.nodes.id
}

resource "azurerm_subnet_network_security_group_association" "apiServer" {
  subnet_id                 = azurerm_subnet.apiServer.id
  network_security_group_id = azurerm_network_security_group.apiServer.id
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource "azurerm_subnet_network_security_group_association" "privateEndpoints" {
  subnet_id                 = azurerm_subnet.privateEndpoints.id
  network_security_group_id = azurerm_network_security_group.privateEndpoints.id
}

resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${var.cluster_name}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-workload-${var.cluster_name}"
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

resource "azurerm_container_registry" "aks" {
  name                          = "acr${var.cluster_name}"
  resource_group_name           = azurerm_resource_group.aks.name
  location                      = azurerm_resource_group.aks.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  tags                          = var.tags
}

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.aks.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "link-acr-${var.cluster_name}"
  resource_group_name   = azurerm_resource_group.aks.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.aks.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "acr" {
  name                = "pe-${azurerm_container_registry.aks.name}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  subnet_id           = azurerm_subnet.privateEndpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${azurerm_container_registry.aks.name}"
    private_connection_resource_id = azurerm_container_registry.aks.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }
}

module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "0.8.3"

  name      = var.cluster_name
  location  = azurerm_resource_group.aks.location
  parent_id = azurerm_resource_group.aks.id

  kubernetes_version    = "1.36.3"
  public_network_access = "Disabled"

  addon_profile_azure_policy = {
    enabled = true
  }

  managed_identities = {
    user_assigned_resource_ids = [azurerm_user_assigned_identity.aks.id]
  }

  oidc_issuer_profile = {
    enabled = true
  }

  security_profile = {
    workload_identity = {
      enabled = true
    }
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
    orchestrator_version = "1.36.3"
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
      orchestrator_version = "1.36.3"
      vnet_subnet_id       = azurerm_subnet.nodes.id
      node_labels = {
        workload = "apps"
      }
      node_taints = ["workload=apps:NoSchedule"]
      upgrade_settings = {
        max_surge = "33%"
      }
    }
    # testpool = {
    #   name                 = "testpool"
    #   type                 = "VirtualMachines"
    #   mode                 = "User"
    #   orchestrator_version = "1.36.3"
    #   vnet_subnet_id       = azurerm_subnet.nodes.id
    #   node_labels = {
    #     workload = "test"
    #   }
    #   upgrade_settings = {
    #     max_surge = "33%"
    #   }
    #   virtual_machines_profile = {
    #     scale = {
    #       manual = [
    #         {
    #           size  = "Standard_D4ds_v5"
    #           count = 2
    #         },
    #         {
    #           size  = "Standard_D8ds_v5"
    #           count = 1
    #         }
    #       ]
    #     }
    #   }
    # }
  }

  enable_rbac = true
  aad_profile = {
    managed           = true
    enable_azure_rbac = true
  }

  tags = var.tags

  depends_on = [azurerm_role_assignment.aksNetworkContributor]
}

resource "azurerm_federated_identity_credential" "workload" {
  name                      = "fic-workloaduser"
  user_assigned_identity_id = azurerm_user_assigned_identity.workload.id
  issuer                    = module.aks.oidc_issuer_profile_issuer_url
  subject                   = "system:serviceaccount:default:workloaduser"
  audience                  = ["api://AzureADTokenExchange"]
}

resource "azurerm_role_assignment" "aksAcrPull" {
  scope                = azurerm_container_registry.aks.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity.objectId
  principal_type       = "ServicePrincipal"

  lifecycle {
    ignore_changes = [principal_id]
  }
}

resource "azapi_resource" "testpool" {
  type      = "Microsoft.ContainerService/managedClusters/agentPools@2026-01-02-preview"
  name      = "testpool"
  parent_id = module.aks.resource_id

  body = {
    properties = {
      mode                = "User"
      type                = "VirtualMachines"
      orchestratorVersion = "1.36.3"
      vnetSubnetID        = azurerm_subnet.nodes.id
      nodeLabels = {
        workload = "test"
      }
      upgradeSettings = {
        maxSurge       = "33%"
        maxUnavailable = "0"
      }
      virtualMachinesProfile = {
        scale = {
          autoscale = {
            size     = "Standard_D4ds_v5"
            minCount = 1
            maxCount = 4
          }
        }
      }
    }
  }

  ignore_missing_property   = true
  ignore_null_property      = true
  schema_validation_enabled = false

  response_export_values = [
    "properties.currentOrchestratorVersion",
    "properties.nodeImageVersion",
    "properties.provisioningState",
    "properties.virtualMachinesProfile.scale",
    "type"
  ]
}

resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-${var.cluster_name}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  ip_tags = {
    FirstPartyUsage = "/Unprivileged"
  }
  tags = var.tags
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