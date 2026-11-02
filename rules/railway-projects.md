# 🚆 Projeto novo no Railway aparece no painel da Ada

Regra global. Todo projeto implantado precisa aparecer em **Infra → Custos** (e **Infra → Ambientes**) no
painel da Ada, para o custo ser visto e o staging poder ser desligado. O painel **não tem cadastro manual**:
ele lê o workspace Railway inteiro (spec `ada-technology/specs/001-infra-railway/`). Projeto que foge do
padrão abaixo simplesmente não aparece, ou aparece sem proteção.

## Ao criar ou provisionar um projeto — OBRIGATÓRIO

1. **Workspace `AdA Technology`** (`42450f5c-a76c-40d9-b77f-cc627906ead1`). Nunca na conta pessoal nem em
   outro workspace: o token do painel não enxerga fora dele. Conferir com `railway list` antes do primeiro deploy.
2. **Nomes de ambiente:** `staging`/`production`, ou `<prefixo>-staging`/`<prefixo>-production`
   (ex.: `cbni-staging`). Staging precisa conter `staging` para ser gerenciável; produção precisa conter
   `production` para ficar protegida contra desligamento. Nome fora disso (`dev`, `prod`, `hml`) → parar e perguntar.
3. **Serviços de banco** com nome começando por `Postgres`, `Redis`, `MySQL` ou `MongoDB` (nome padrão do
   Railway — não renomear). O painel usa o nome para desligar banco por último e ligar primeiro.
4. **Depois do primeiro deploy**, conferir que o projeto aparece em Infra → Custos.
   Enquanto a spec 001 não estiver implantada, adicionar o projeto na tabela de inventário
   (`spec.md` §3) da spec.

## Projeto que usa bucket Railway — OBRIGATÓRIO

Registrada em 2026-11-01, no `financing-chatbot`: produção usava o bucket de staging com credenciais copiadas à
mão, e as URLs assinadas passaram a responder 403 `SignatureDoesNotMatch` nos dois ambientes.

1. **Um bucket por ambiente.** Produção nunca aponta para o bucket de staging, nem o contrário: compartilhar mistura
   dado de cliente com dado de teste, e rotacionar a chave de um ambiente derruba o outro.
2. **Credenciais só por referência ao bucket** (`ACCESS_KEY_ID`, `SECRET_ACCESS_KEY`, `BUCKET`, `ENDPOINT`, `REGION`
   como `${{<bucket>.VARIAVEL}}`). Proibido colar o valor: a cópia não acompanha a recriação das credenciais.
3. **Desligar e religar nunca mexe em variável nem em credencial**: só `deploymentStop` e `deploymentRestart`.
   Religar por redeploy sobe o código da branch ligada ao serviço, não o que estava rodando.
4. **O serviço fica ligado à branch do seu ambiente** (staging na `staging`). Mudar variável dispara deploy a partir
   dela: ligado à `main`, o staging volta para o código de produção sem nenhum aviso.
5. **Trocar o bucket de um ambiente em uso é migração, nesta ordem:** criar o bucket, aplicar o CORS, copiar os
   objetos com as mesmas chaves e `content-type`, conferir, e só então trocar as variáveis. Trocar antes deixa os
   arquivos existentes em 404 até o fim da cópia. Nada é apagado da origem na migração.
6. **Depois de todo deploy e religamento, conferir um objeto real** por URL assinada (o logo serve) e exigir 200.
   Credencial errada não derruba o boot nem o health check: o deploy fica verde com os arquivos quebrados.

Nunca imprimir credencial para comparar: comparar por hash.

## Fora do Railway

Projeto hospedado em outro lugar (Vercel, AWS, VPS) não entra no painel. **Parar e perguntar** antes de
implantar fora do Railway: ou o projeto vai para o workspace, ou a exceção fica registrada no inventário com
o motivo.
