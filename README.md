# tf-ca
*Simple Terraform-based SSL CA for local setups and testing purposes*

## Quickstart
- Copy `config.auto.tfvars.example` to `config.auto.tfvars` and adjust it to your needs
- `terraform init`
- `terraform apply`
- Generated files are located in `./certs`:
  - `example.com.crt`: The CA cert
  - `servers`: Subfolders for each configured server - containing the private key, the signed (server_auth) cert and the 'chained' cert for the server in PEM format
  - `clients`: Subfolders for each configured client - containing the private key, the signed (client_auth) cert in PEM format and key/cert packaged as P12 archive
