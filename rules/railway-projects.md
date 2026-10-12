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

## Fora do Railway

Projeto hospedado em outro lugar (Vercel, AWS, VPS) não entra no painel. **Parar e perguntar** antes de
implantar fora do Railway: ou o projeto vai para o workspace, ou a exceção fica registrada no inventário com
o motivo.
