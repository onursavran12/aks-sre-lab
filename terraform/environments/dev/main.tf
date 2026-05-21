provider "azurerm" {
  features {}
}

locals {
  name_prefix = "${var.project}-${var.environment}"

  resource_group_name = "rg-${local.name_prefix}"
  aks_name            = "aks-${local.name_prefix}"
  acr_name            = replace("acr${var.project}${var.environment}", "-", "")

  vnet_name   = "vnet-${local.name_prefix}"
  subnet_name = "snet-aks-${var.environment}"

  common_tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.50.0.0/16"]
  tags                = local.common_tags
}

resource "azurerm_subnet" "aks" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.50.1.0/24"]
}

resource "azurerm_container_registry" "main" {
  name                = substr(local.acr_name, 0, 50)
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = local.common_tags
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = local.aks_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = local.aks_name
  kubernetes_version  = var.kubernetes_version

  sku_tier = "Free"

  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_vm_size
    vnet_subnet_id               = azurerm_subnet.aks.id
    auto_scaling_enabled         = true
    min_count                    = 1
    max_count                    = 2
    os_disk_size_gb              = 64
    os_sku                       = "Ubuntu"
    only_critical_addons_enabled = true
    temporary_name_for_rotation  = "tempsys"

    upgrade_settings {
      max_surge = "10%"
    }
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    load_balancer_sku   = "standard"

    service_cidr   = "10.60.0.0/16"
    dns_service_ip = "10.60.0.10"
    pod_cidr       = "10.244.0.0/16"
    outbound_type  = "loadBalancer"
  }

  tags = local.common_tags
}

resource "azurerm_kubernetes_cluster_node_pool" "apps" {
  name                  = "apps"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_node_vm_size
  mode                  = "User"
  vnet_subnet_id        = azurerm_subnet.aks.id

  auto_scaling_enabled = true
  min_count            = var.user_node_min_count
  max_count            = var.user_node_max_count

  os_disk_size_gb = 64
  os_sku          = "Ubuntu"

  node_labels = {
    workload = "apps"
  }

  upgrade_settings {
    max_surge = "10%"
  }

  tags = local.common_tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}
