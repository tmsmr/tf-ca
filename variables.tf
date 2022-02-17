variable "ca_cert_validity_hours" {
  default = 87600
}

variable "ca_cn" {}

variable "server_cns" {}

variable "client_cns" {}

variable "server_cert_validity_hours" {
  default = 8760
}

variable "client_cert_validity_hours" {
  default = 8760
}

variable "p12_pass" {}
