terraform {
  required_providers {
    aws = {
      version = "~> 4.25"
    }
    google = {
      version = "~> 4.31"
    }
    vsphere = {
      version = "~> 1.2"
    }
    azurerm = {
      version = "~> 3.17"
    }
    helm = {
      version = "~> 2.6"
    }
    null = {
      version = "~> 3.0"
    }
    tls = {
      version = "~> 3.1"
    }
    kubermatic = {
      version = "~> 0.1"
      source = "kubermatic/kubermatic"
    }
  }
}
