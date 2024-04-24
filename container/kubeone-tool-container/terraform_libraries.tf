terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.1.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.27.0"
    }
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.1.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.10.0"
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
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "1.47.0"
    }
    time = {
      source = "hashicorp/time"
      version = "0.11.1"
    }
  }
}
