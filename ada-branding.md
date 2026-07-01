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

## Modo e paleta

- **Sempre light mode** — fundo `#f5f7fa`, cards brancos `#ffffff`
- Acentos variam conforme o produto documentado (verde WhatsApp, azul tech, etc.)
- Nunca usar fundos escuros no corpo do documento

## Entrega para cliente

Ao finalizar o documento, oferecer opção de embutir o logo em **base64** para gerar um arquivo HTML único que não depende de arquivos externos ao ser enviado.
