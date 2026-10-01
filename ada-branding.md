---
paths:
  - "**/*.html"
  # O rodapé de atribuição do produto vive em componente, não em documento.
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
---

# Ada Technology — Identidade Visual para Documentos de Cliente

## Tipografia

- **Fonte principal:** Space Grotesk (Google Fonts)
- **Import:** `<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300;400;500;600;700&display=swap" rel="stylesheet" />`
- **font-family:** `'Space Grotesk', 'Segoe UI', system-ui, sans-serif`
- **Títulos grandes:** `letter-spacing: -0.02em` — aperta levemente para look premium
- **Section labels (uppercase):** `letter-spacing: 0.12em; font-size: 0.82rem` — abre bastante para respirar
- **Preços:** `letter-spacing: -0.03em; font-weight: 700`

Toda documentação HTML voltada para clientes (propostas comerciais, apresentações, relatórios de produto) deve seguir este padrão de identidade visual.

## Logo

- **Versão preferencial:** `ada-logo-transparent.png` — fundo transparente, funciona em qualquer cor de fundo
- **Versão light alternativa:** `ada-logo-light.png` — com fundo branco/cinza, usar apenas quando transparente não for suportado
- **Características:** ícone pirâmide em azul degradê, texto "ADA" azul escuro navy, "TECHNOLOGY" em azul claro
- **Arquivo global:** `~/.claude/ada-logo-transparent.png` e `~/.claude/ada-logo-light.png`
- **Nunca usar** a versão neon verde escura (fundo dark navy) em documentos de modo light

## Topbar

```html
<!-- Sempre no topo, antes do hero -->
<div class="topbar">
  <img src="ada-logo-light.png" alt="Ada Technology" class="topbar-logo" />
  <span class="topbar-label">Proposta Comercial · Confidencial</span>
</div>
```

```css
.topbar {
  background: #ffffff;
  border-bottom: 1px solid #e5e7eb;
  padding: 12px 32px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.topbar-logo { height: 52px; width: auto; }
.topbar-label { font-size: 0.78rem; color: #9ca3af; letter-spacing: 0.06em; text-transform: uppercase; }
```

## Footer / Copyright

```html
<div class="footer">
  <img src="ada-logo-light.png" alt="Ada Technology" style="height:44px;margin-bottom:12px;opacity:0.8;" /><br/>
  <strong>Ada Technology</strong><br/>
  © 2026 Ada Technology. Todos os direitos reservados.<br/>
  Documento confidencial gerado exclusivamente para apresentação comercial.
</div>
```

## Atribuição no rodapé do produto (software, não documento)

As seções acima são de **documento HTML entregue a cliente**. Esta não: vale para toda interface
que o usuário final abre — painel, landing, portal, PWA. O cabeçalho de copyright do arquivo-fonte
(`code-standart.md` §17) não aparece na tela para ninguém; a atribuição abaixo é a única saída do
produto para quem o fez.

**Toda app com interface renderizada fecha com um rodapé que nomeia a Ada Technology**, num
componente único por app — rodapé que mora numa tela só é rodapé que falta nas outras.

```tsx
const ADA_WEBSITE_URL = 'https://adatechnology.com.br'
const ADA_MARK_SOURCE = '/icons/ada-technology.png'

<footer>
  <img alt="" aria-hidden="true" src={ADA_MARK_SOURCE} />
  <span>
    © {new Date().getFullYear()}{' '}
    <a href={ADA_WEBSITE_URL} target="_blank" rel="noreferrer">Ada Technology</a> — {PRODUCT_NAME}
  </span>
</footer>
```

- **Produto de marca branca** (a landing de um cliente, onde o nome dele assina a página) troca a
  frase, nunca a presença: o copyright fica com o cliente e a Ada entra numa segunda linha —
  `Plataforma <Produto> — uma solução <a>Ada Technology</a>`.
- `rel="noreferrer"` é obrigatório: sem ele a aba aberta herda `window.opener` e o caminho de volta
  para a sessão.
- O ano sai do relógio. Rodapé com ano fixo envelhece sem ninguém notar.
- A marca é sempre o mesmo arquivo (`ada-technology.png`) em todas as apps — duas apps assinando com
  desenhos diferentes é o produto se apresentando como dois produtos.
- **Produto que usa WhatsApp Cloud API: a atribuição é bloqueante, não recomendação.** A análise do
  nome de exibição da Meta procura no site a ligação com o Portfólio Empresarial, e sem ela o nome
  é recusado ou aprovado sujo. Detalhe e checklist em `rules/whatsapp-cloud-api.md` § *O nome de
  exibição é aprovado pelo site*.
- **Congelar em teste de contrato.** A ausência de rodapé não quebra build, não quebra teste e não
  aparece em review; só aparece quando a Meta reprova o nome de exibição ou o cliente pergunta quem
  fez. Referência: `apps/frontend-transportada/test/design-system/application-footer.contract.ts` e
  `apps/frontend-landing/test/design-system/ada-attribution.contract.ts` no TransportAdA.

## Modo e paleta

- **Sempre light mode** — fundo `#f5f7fa`, cards brancos `#ffffff`
- Acentos variam conforme o produto documentado (verde WhatsApp, azul tech, etc.)
- Nunca usar fundos escuros no corpo do documento

## Entrega para cliente

Ao finalizar o documento, oferecer opção de embutir o logo em **base64** para gerar um arquivo HTML único que não depende de arquivos externos ao ser enviado.
