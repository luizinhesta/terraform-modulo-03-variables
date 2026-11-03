# Conceitos Terraform do Módulo 03

## `variable`

Parâmetro de entrada do código. Acessado com `var.<nome>`.

```hcl
variable "environment" {
  type        = string
  description = "Nome lógico do ambiente."
  default     = "dev"
}
```

| Argumento | Para que serve |
|---|---|
| `type` | Tipo esperado; erros aparecem antes de chamar a AWS |
| `default` | Valor usado se nada for informado. Sem `default`, a variável é **obrigatória** e o Terraform pergunta no terminal |
| `description` | Documentação (aparece em prompts e ferramentas) |
| `nullable` | Define se `null` é aceito. Com `default = null`, o valor "ausente" é válido |
| `validation` | Regra personalizada com `condition` e `error_message` |

## Tipos

| Tipo | Exemplo neste módulo |
|---|---|
| `string` | `environment`, `project_prefix`, `price_class` |
| `number` | `default_ttl_seconds` |
| `bool` | `enable_ipv6` |
| `list(string)` | `technologies` (ordem preservada) |
| `map(string)` | `extra_tags`, `contact_links` (chave => valor) |
| `object({...})` | `profile` (campos nomeados de tipos diferentes) |
| `list(object({...}))` | `projects` |

## `validation`

```hcl
validation {
  condition     = contains(["dev", "hml"], var.environment)
  error_message = "O ambiente deve ser \"dev\" ou \"hml\"."
}
```

Falha no `plan`/`validate` com a sua mensagem, sem tocar na AWS. O `can(regex(...))` do prefixo transforma erro de regex em `false`.

## `nullable` e condicional

`owner` aceita `null`. No `locals`, `var.owner == null ? {} : { Owner = var.owner }` inclui a tag somente quando informada. `merge()` combina maps (o último vence).

## Como informar valores (precedência crescente)

1. `default` da variável.
2. `terraform.tfvars` e `terraform.tfvars.json` (carregados automaticamente).
3. `*.auto.tfvars` (carregados automaticamente, em ordem alfabética).
4. `-var-file=arquivo` e `-var="nome=valor"` (na ordem da linha de comando).

Variáveis de ambiente `TF_VAR_<nome>` também funcionam e ficam entre o `default` e os arquivos.

Em caso de conflito, o que vem depois na lista vence.

```powershell
terraform plan -var="environment=hml"
terraform plan -var-file="hml.tfvars.example"
```

## Arquivos de exemplo e Git

Versionamos apenas `*.tfvars.example`. Os `.tfvars` reais são ignorados pelo `.gitignore`, pois podem conter dados privados. O comando `-var-file` aceita qualquer nome de arquivo, inclusive `dev.tfvars.example`.

## `output`

Valores exibidos após o `apply` e consultáveis a qualquer momento:

```powershell
terraform output                    # todos
terraform output site_url           # um específico
terraform output -raw site_url      # sem aspas (bom para scripts)
terraform output -json              # formato JSON
```

Os outputs deste módulo usam atributos do S3 (`id`, `arn`, `bucket_regional_domain_name`) e do CloudFront (`id`, `domain_name`).

## `sensitive`

```hcl
output "bucket_arn_sensitive_demo" {
  value     = aws_s3_bucket.site.arn
  sensitive = true
}
```

- O terminal mostra `<sensitive>`.
- `terraform output -raw bucket_arn_sensitive_demo` revela o valor.
- **O valor continua em texto puro no state.** `sensitive` só reduz a exposição acidental em tela e logs.
- O ARN não é segredo; o exemplo é apenas didático. Nunca use este módulo para guardar senhas.

## Ambientes e state (risco importante)

Os arquivos `dev` e `hml` servem, neste momento, para **comparar** configurações com `plan`.

Aplicar `dev` e depois `hml` sobre o **mesmo state** não cria dois ambientes: o nome do bucket inclui o ambiente, então o Terraform entende que o bucket do dev deve ser **substituído** (`-/+`) pelo do hml. Isso destrói o conteúdo anterior e recria a infraestrutura. Para ter dois ambientes simultâneos, é preciso states separados (cópias da pasta, workspaces ou backends distintos), assunto de etapas futuras.

## Conceitos de apoio

Aparecem no código, mas o foco são as variáveis e os outputs.

| Conceito | Explicação curta |
|---|---|
| `locals` | Valores calculados a partir de variáveis (`local.name_prefix`, `local.tags`). Variável é entrada de fora; `local` é cálculo interno |
| `merge(a, b, ...)` | Junta maps; em chaves repetidas, o último vence |
| `cond ? a : b` | Condicional: escolhe `a` se `cond` for verdadeira, senão `b` |
| `contains(lista, valor)` | Verdadeiro se o valor está na lista (usado nas validações) |
| `can(expr)` | Devolve `true` se a expressão não der erro (usado com `regex` na validação do prefixo) |
| `jsonencode(...)` | Converte HCL em JSON (policy e `config.json`) |
| `for_each` e `fileset` | Um `aws_s3_object` por arquivo da pasta `application`, como no módulo 02 |

Não há `data "aws_cloudfront_cache_policy"` neste módulo: a política de cache é criada por `aws_cloudfront_cache_policy.site`, para que `default_ttl_seconds` tenha efeito real.

## Gerando arquivos a partir de variáveis

O `aws_s3_object.config` recebe `content = jsonencode(local.site_config)`. As variáveis do portfólio viram o `config.json` que o site lê. É a mesma ideia de gerar arquivos de configuração em projetos reais.
