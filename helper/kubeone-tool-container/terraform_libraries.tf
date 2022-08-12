terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.45.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 3.71.0"
    }
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.0.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.63.0"
    }
    helm = {
      version = "~> 2.6"
    }
    null = {
      version = "~> 3.0"
    }
    random = {
      version = "~> 3.3.2"
      source  = "hashicorp/random"
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
