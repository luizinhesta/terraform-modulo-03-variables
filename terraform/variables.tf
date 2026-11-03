# -----------------------------------------------------------------------------
# variables.tf - Entradas do módulo
#
# Uma variável é um PARÂMETRO de entrada. Sintaxe:
#   variable "nome" {
#     type        = ...   # tipo esperado
#     default     = ...   # valor padrão (sem default => obrigatória)
#     description = "..." # documentação
#     nullable    = ...   # aceita null?
#     validation { ... }  # regras extras
#   }
# Uso no código: var.nome
# -----------------------------------------------------------------------------

# --- string -------------------------------------------------------------------
variable "aws_region" {
  type        = string
  description = "Região AWS onde os recursos serão criados."
  default     = "us-east-1"
}

variable "project_prefix" {
  type        = string
  description = "Prefixo dos nomes dos recursos (minúsculas, números e hífens)."
  default     = "tfpratica-m03"

  # validation: o Terraform recusa o valor ANTES de qualquer chamada à AWS.
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,18}[a-z0-9]$", var.project_prefix))
    error_message = "O prefixo deve ter de 3 a 20 caracteres, usar apenas letras minúsculas, números e hífens, e não começar nem terminar com hífen."
  }
}

variable "environment" {
  type        = string
  description = "Nome lógico do ambiente (dev ou hml)."
  default     = "dev"

  validation {
    condition     = contains(["dev", "hml"], var.environment)
    error_message = "O ambiente deve ser \"dev\" ou \"hml\"."
  }
}

variable "price_class" {
  type        = string
  description = "Classe de preço do CloudFront."
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "Use PriceClass_100, PriceClass_200 ou PriceClass_All."
  }
}

# --- bool ---------------------------------------------------------------------
variable "enable_ipv6" {
  type        = bool
  description = "Habilita IPv6 na distribuição CloudFront."
  default     = true
}

# --- number -------------------------------------------------------------------
variable "default_ttl_seconds" {
  type        = number
  description = "Tempo padrão (segundos) de cache no CloudFront. Entre 0 e 86400."
  default     = 300

  validation {
    condition     = var.default_ttl_seconds >= 0 && var.default_ttl_seconds <= 86400
    error_message = "default_ttl_seconds deve estar entre 0 e 86400."
  }
}

# --- map ----------------------------------------------------------------------
variable "extra_tags" {
  type        = map(string)
  description = "Tags adicionais aplicadas aos recursos (chave = valor)."
  default     = {}
}

# --- nullable -----------------------------------------------------------------
# Com nullable = true (padrão) e default = null, "não informar" é um valor válido.
variable "owner" {
  type        = string
  description = "Responsável pelo ambiente. Se null, a tag Owner não é criada."
  default     = null
  nullable    = true
}

# --- object -------------------------------------------------------------------
# Agrupa vários campos de tipos diferentes em uma única variável.
# Valores genéricos: NÃO coloque dados pessoais reais sem querer publicá-los,
# pois irão para um site público.
variable "profile" {
  type = object({
    name     = string
    headline = string
    bio      = string
  })
  description = "Dados de apresentação exibidos no portfólio (públicos)."
  default = {
    name     = "Seu Nome"
    headline = "Engenheiro(a) de Nuvem em formação"
    bio      = "Texto de exemplo. Substitua pelo seu, via arquivo de variáveis."
  }
}

# --- list ---------------------------------------------------------------------
variable "technologies" {
  type        = list(string)
  description = "Tecnologias exibidas no portfólio (a ordem é preservada)."
  default     = ["Terraform", "Amazon S3", "Amazon CloudFront", "AWS CLI", "Git"]
}

# --- list de object -----------------------------------------------------------
variable "projects" {
  type = list(object({
    title       = string
    description = string
    services    = list(string)
  }))
  description = "Projetos exibidos como cards."
  default = [
    {
      title       = "Site estático no S3"
      description = "Primeiro site publicado com Terraform."
      services    = ["S3"]
    },
    {
      title       = "Landing page com CDN"
      description = "S3 privado com CloudFront e OAC."
      services    = ["S3", "CloudFront"]
    },
    {
      title       = "Portfólio parametrizado"
      description = "Infraestrutura configurável por variáveis."
      services    = ["S3", "CloudFront", "Terraform"]
    }
  ]
}

# --- map de string para links --------------------------------------------------
variable "contact_links" {
  type        = map(string)
  description = "Links de contato demonstrativos (nome => URL)."
  default = {
    GitHub   = "https://github.com/exemplo"
    LinkedIn = "https://www.linkedin.com/in/exemplo"
    Email    = "mailto:contato@example.com"
  }
}
