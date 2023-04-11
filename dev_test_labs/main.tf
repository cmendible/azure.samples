resource "azurerm_resource_group" "rg" {
  name     = "dev-test-labs"
  location = "westeurope"
}

resource "azapi_resource" "lab" {
  name                      = "lab-devtestlab"
  parent_id                 = azurerm_resource_group.rg.id
  type                      = "Microsoft.DevTestLab/labs@2018-10-15-preview"
  location                  = azurerm_resource_group.rg.location
  schema_validation_enabled = false # Required to use the API version 2018-10-15-preview
  body = jsonencode({
    properties = {
      browserConnect = "Enabled",
      announcement = {
        enabled  = "Disabled"
        expired  = false
        markdown = ""
        title    = ""
      }
      environmentPermission                = "Reader"
      labStorageType                       = "Premium"
      mandatoryArtifactsResourceIdsLinux   = []
      mandatoryArtifactsResourceIdsWindows = []
      premiumDataDisks                     = "Disabled"
      support = {
        enabled  = "Disabled"
        markdown = ""
      }
    }
  })
}

resource "azapi_resource" "lab_network" {
  name      = "lab-network"
  parent_id = azapi_resource.lab.id
  type      = "Microsoft.DevTestLab/labs/virtualnetworks@2018-09-15"
  location  = azurerm_resource_group.rg.location
  body = jsonencode({
    properties = {
      description                = "lab-network"
      externalProviderResourceId = "${azurerm_virtual_network.lab.id}"
      subnetOverrides = [
        {
          labSubnetName                = "${azurerm_subnet.lab.name}"
          resourceId                   = "${azurerm_subnet.lab.id}"
          useInVmCreationPermission    = "Allow"
          usePublicIpAddressPermission = "Deny"
        }
      ]
    }
  })
}

resource "azurerm_dev_test_schedule" "on" {
  name                = "LabVmAutoStart"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  lab_name            = azapi_resource.lab.name

  weekly_recurrence {
    time      = "0900"
    week_days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  }

  time_zone_id = "Central Europe Standard Time"
  task_type    = "LabVmsStartupTask"

  notification_settings {
  }

  status = "Enabled"
}

resource "azurerm_dev_test_schedule" "off" {
  name                = "LabVmsShutdown"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  lab_name            = azapi_resource.lab.name

  daily_recurrence {
    time = "1900"
  }

  time_zone_id = "Central Europe Standard Time"
  task_type    = "LabVmsShutdownTask"

  notification_settings {
  }

  status = "Enabled"
}

resource "azurerm_dev_test_windows_virtual_machine" "vm" {
  name                       = "lab-vm"
  lab_name                   = azapi_resource.lab.name
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  size                       = "Standard_DS2"
  username                   = "myuser"
  password                   = "<replace password here>"
  lab_virtual_network_id     = azapi_resource.lab_network.id
  lab_subnet_name            = azurerm_subnet.lab.name
  storage_type               = "Premium"
  notes                      = "Some notes about this Virtual Machine."
  disallow_public_ip_address = true
  allow_claim                = true

  gallery_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  tags = {}
}

resource "azurerm_dev_test_policy" "vm_count" {
  name                = "LabVmCount"
  policy_set_name     = "default"
  lab_name            = azapi_resource.lab.name
  resource_group_name = azurerm_resource_group.rg.name
  fact_data           = ""
  threshold           = "100"
  evaluator_type      = "MaxValuePolicy"
}

resource "azurerm_dev_test_policy" "image" {
  name                = "GalleryImage"
  policy_set_name     = "default"
  lab_name            = azapi_resource.lab.name
  resource_group_name = azurerm_resource_group.rg.name
  fact_data           = "WindowsServer"
  threshold           = "['Standard_DS2']"
  evaluator_type      = "AllowedValuesPolicy"
}

resource "azurerm_dev_test_policy" "vm_per_user" {
  name                = "UserOwnedLabVmCount"
  policy_set_name     = "default"
  lab_name            = azapi_resource.lab.name
  resource_group_name = azurerm_resource_group.rg.name
  fact_data           = ""
  threshold           = "1"
  evaluator_type      = "MaxValuePolicy"
}

resource "azurerm_virtual_network" "lab" {
  name                = "lab-network"
  address_space       = ["10.0.0.0/20", "10.1.0.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "lab" {
  name                 = "${azurerm_virtual_network.lab.name}Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.0.0.0/20"]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "bastion-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "labbastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}
