# A região agora vem de uma variável (veja variables.tf).
# Credenciais continuam vindo do AWS CLI (AWS_PROFILE).
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "terraform-na-pratica"
      Module    = "modulo-03-variables"
      ManagedBy = "terraform"
    }
  }
}
