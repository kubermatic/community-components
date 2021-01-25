terraform {
  required_providers {
    aws = {
      version = "~> 3.2"
    }
    google = {
      version = "~> 2.0"
    }
    vsphere = {
      version = "~> 1.2"
    }
    azurerm = {
      version = "~> 2.4"
    }
    helm = {
      version = "~> 2.0"
    }
    kubermatic = {
      version = "~> 0.1"
      source = "kubermatic/kubermatic"

    }
  }
}
