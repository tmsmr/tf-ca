terraform {
  required_providers {
    pkcs12 = {
      source = "chilicat/pkcs12"
      version = "0.0.7"
    }
  }
}

provider "pkcs12" {}