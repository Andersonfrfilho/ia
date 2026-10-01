---
paths:
  - "**/*whatsapp*/**"
  - "**/*Whatsapp*/**"
  - "**/*WhatsApp*/**"
  - "**/*webhook*/**"
---

# 📱 WhatsApp Cloud API — diagnóstico antes de código

Quadro recorrente: **a mensagem do cliente chega e nenhuma resposta sai.** Ele parece bug de
aplicação e quase nunca é. Antes de abrir handler, fluxo ou SDK, confira os três estados abaixo —
eles falham de forma independente e cada um imita o sintoma dos outros.

| O que | Comando | Estado correto |
|---|---|---|
| Escopo do token | `GET /debug_token?input_token=…` com app token `{app-id}\|{app-secret}` | contém `whatsapp_business_messaging` |
| Número no Cloud API | `GET /{phone_number_id}` | `status: CONNECTED` + `platform_type: CLOUD_API` |
| App assinado na WABA | `GET /{waba_id}/subscribed_apps` | o app aparece na lista |

## A assimetria que explica o sintoma

**Entrada e saída usam credenciais diferentes.** O webhook valida a assinatura
`X-Hub-Signature-256` com o `APP_SECRET`; todo envio usa o `ACCESS_TOKEN`. Token sem escopo
produz exatamente "chega mas não sai" — e o erro da Meta **culpa o número**:

```
(#100, subcode 33) Object with ID '<phone_number_id>' does not exist,
cannot be loaded due to missing permissions, or does not support this operation.
```

O número existe. Quem está cego é o token. Não troque o número por causa desse erro.

`whatsapp_business_management` e `whatsapp_business_messaging` são escopos distintos: o primeiro
registra e assina, o segundo envia. Faltar o primeiro trava a ativação; faltar o segundo trava o
envio.

## Número que nunca foi registrado

`status: PENDING` + `platform_type: NOT_APPLICABLE` significa número **nunca ligado ao Cloud
API**, mesmo com `code_verification_status: VERIFIED` — esse campo cobre só o SMS de posse, que é
passo anterior e diferente.

Conserto: `POST /{phone_number_id}/register` com `messaging_product` e `pin`.

**O `pin` não é código que a Meta envia** — é a senha de verificação em duas etapas que se
*define* naquela chamada. Não há o que buscar. Gere, **grave em lugar durável antes de usar**, e
nunca imprima: perder o valor custa re-registro por suporte da Meta, e errar seis vezes bloqueia
o registro por horas.

## O painel de desenvolvedor não serve para tudo

O console de API (`developers.facebook.com` → app → WhatsApp → Configuração da API) fica amarrado
à WABA vinculada ao caso de uso do app. **Número de outra WABA ele não enxerga** — a tela segue
mostrando o número antigo, inclusive no cURL de exemplo. Para registrar, use o Gerenciador do
WhatsApp (`business.facebook.com` → Ferramentas da conta → Números de telefone) ou a API.

## `130497` é da conta, não do número

```
130497  Business account is restricted from messaging users in this country
```

Restrição **da WABA**. Trocar de número dentro da mesma WABA não resolve; mover para uma WABA
verificada própria resolveu. Checar também **forma de pagamento** na WABA, que restringe conversa
iniciada pela empresa.

Esse erro chega como **status de entrega no webhook**, não como falha da chamada de envio: a API
responde 200 e a mensagem não chega. **Logue o callback de status** — sem ele o sintoma é
silêncio, indistinguível de bug de fluxo.

## Prova de envio

```
webhook_processed  messages:1   ← cliente escreveu
webhook_processed  statuses:1   ← saiu
webhook_processed  statuses:1   ← entregue
```

Callback de status só existe para mensagem que a Meta aceitou. `messages:1` sem `statuses`
depois é o quadro "chega mas não sai".

## O nome de exibição é aprovado pelo site, não pelo app

**Projeto que usa WhatsApp Cloud API exige a atribuição da Ada Technology no rodapé do site antes
de pedir análise do nome de exibição.** Não é preferência de marca: é o que a revisão da Meta
procura.

Ao analisar o nome de exibição (`Quick Cart`, `Fernandes Transportadora`), a Meta verifica se
existe ligação comprovável entre esse nome e o **Portfólio Empresarial** que pede a aprovação —
`AdA Technology`, ID `27208590128791050`. Sem uma menção pública ligando os dois, o pedido é
recusado ou aprovado com o nome sujo (`Ada Technology — Quick Cart`), que vaza o fornecedor para
dentro da conversa do cliente final.

O site oficial do produto é a prova. Rodapé com uma destas frases basta:

- `Uma solução tecnológica Ada Technology`
- `Plataforma desenvolvida por Ada Technology`
- `Powered by Ada Technology`

Marcação e demais exigências (link com `rel="noreferrer"`, ano do relógio, mesma marca em todas as
apps, teste de contrato) estão em `ada-branding.md` § *Atribuição no rodapé do produto* — a
diferença é que ali é norma de produto e **aqui é bloqueante**: sem ela o nome não sai da análise.

Checar junto, porque falham no mesmo pedido e com mensagens parecidas:

- O site tem de exibir o **nome de exibição pedido** com destaque — nome na análise que não aparece
  na página é recusa.
- Logo e foto de perfil do WhatsApp coerentes com o site.
- Forma de pagamento ativa no portfólio (a mesma que o `130497` cobra — ver acima).

⚠️ **Procedência:** esta seção veio de atendimento da Meta, não da documentação publicada. As
frases e o critério do portfólio não foram conferidos contra
`developers.facebook.com/docs/whatsapp`. Antes de tratar uma recusa como esperada, confirme na
documentação — o processo de análise de nome muda sem aviso.

## Higiene

- Segredo gravado por substituição de comando (`--set "K=$(cmd)"`), conferido por `shasum`,
  nunca ecoado. **Valor que apareceu em terminal ou log é valor queimado — rotacione.**
- Variável gravada com `--skip-deploys` **não vale até o redeploy**.
- Implementação de referência: `quickcart/scripts/register-whatsapp-number.sh` e
  `quickcart/docs/WHATSAPP-NUMERO-CLOUD-API.md`.
