# Exercícios — Módulo 03

Tente antes de consultar as respostas.

## Exercícios guiados

1. **Prefixo.** Informe `-var="project_prefix=meulab"` em um `plan`. Quais recursos mudam de nome? O bucket é alterado ou substituído?
2. **Ambiente lógico.** Rode `plan` com `-var="environment=hml"`. O que muda além do nome do bucket? (Ainda sem aplicar.)
3. **Tags por map.** Em `terraform.tfvars`, acrescente `extra_tags = { Time = "plataforma" }`. Rode `plan`. Qual é o impacto no bucket e na distribuição?
4. **Testar validação.** Use `-var="environment=prod"` e depois `-var="project_prefix=-abc"`. Leia as mensagens.
5. **Arquivos de exemplo.** Compare `dev.tfvars.example` com `hml.tfvars.example`. Liste as diferenças.
6. **Planos distintos.** Rode `plan` com cada arquivo. Compare o `default_ttl` da política de cache e o `is_ipv6_enabled`.
7. **Outputs.** Após o apply, use `terraform output site_url`, `terraform output -json` e `terraform output -raw distribution_id`.
8. **auto.tfvars.** Crie `tema.auto.tfvars` com `owner = "voce"`. Rode `plan` sem informar nada. O valor foi carregado? (O arquivo é ignorado pelo Git.)

### Evidências do laboratório

**Exercício 1 (prefixo).** Com `-var="project_prefix=meulab"`, a cache policy e a distribuição são atualizadas no lugar (`~`), e o nome do bucket muda, o que indica substituição (`-/+`).

![Plano com project_prefix=meulab: cache policy e distribuição](../imagens/imagem%20(11).png)

Nos outputs, os valores do bucket aparecem como `known after apply`, porque o novo bucket ainda não existe.

![Outputs do plano com project_prefix=meulab](../imagens/imagem%20(10).png)

**Exercício 2 (ambiente lógico).** Com `-var="environment=hml"`, mudam as tags `Environment` e `Name`, e o nome do bucket passa a ter `-hml-`.

![Plano com environment=hml](../imagens/imagem%20(12).png)

**Exercícios 5 e 6 (arquivos de exemplo).** Os planos com `dev.tfvars.example` e `hml.tfvars.example` estão em [IMPLANTACAO.md](IMPLANTACAO.md#8-comparar-dev-e-hml-somente-plano).

## Desafios independentes

1. Crie uma variável `bool` chamada `enable_compression` e use-a no `compress` do cache behavior.
2. Adicione uma `validation` em `extra_tags` impedindo a chave `Environment` (ela já é definida pelo módulo).
3. Troque `technologies` por um `set(string)` e observe o efeito na ordem.
4. Crie um output sensível com o `domain_name` e descreva por que isso **não** serve para guardar segredos.
5. Use `TF_VAR_environment=hml` e confira com `plan` qual valor venceu quando há também `terraform.tfvars` com `dev`.

## Critérios de sucesso

- Você prevê qual fonte de valor vence em um conflito.
- Você diferencia alteração no lugar de substituição ao mudar variáveis.

---

## Respostas comentadas

**1.** O nome do bucket muda, e isso é substituição (`-/+`). A cache policy e o OAC também usam `local.name_prefix`; seus nomes mudam e o plano mostrará o efeito de cada um (leia o plano completo; a distribuição é alterada porque referencia esses recursos).

**2.** Muda `Environment` nas tags, o nome do bucket (substituição), nomes de OAC e cache policy e o `config.json` (badge de ambiente).

**3.** Tags são mutáveis: `~ update in-place` no bucket e na distribuição.

**4.** Cada erro vem da sua `error_message`. A validação roda antes de qualquer chamada à AWS.

**5.** Diferem `environment`, `default_ttl_seconds`, `enable_ipv6`, `owner` e a tag `Tier`.

**6.** DEV tem TTL 0 e IPv6 desligado; HML tem TTL 600 e IPv6 ligado. Lembre que o plano é calculado em relação ao state atual.

**7.** `-raw` remove aspas, ideal para variáveis de shell; `-json` é ideal para ferramentas.

**8.** Sim. `*.auto.tfvars` é carregado automaticamente, com precedência maior que `terraform.tfvars`.

**Desafio 1.**
```hcl
variable "enable_compression" {
  type    = bool
  default = true
}
# no cache behavior:
compress = var.enable_compression
```

**Desafio 2.**
```hcl
validation {
  condition     = !contains(keys(var.extra_tags), "Environment")
  error_message = "A tag Environment é reservada."
}
```
(No Terraform 1.9+, condições de validação podem referenciar outras variáveis; para esta, basta a própria.)

**Desafio 3.** `set` não garante ordem e remove duplicados; o JSON pode mudar de ordem. Para listas ordenadas na tela, mantenha `list`.

**Desafio 4.** O valor é ocultado na tela, mas fica em texto puro no state e em `terraform output -raw`. Segredos exigem um serviço apropriado (por exemplo Secrets Manager), tema de outra etapa.

**Desafio 5.** `TF_VAR_*` tem precedência menor que `terraform.tfvars`; vence `dev`. Para sobrepor, use `-var` ou `-var-file`.
