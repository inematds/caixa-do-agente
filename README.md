# caixa-do-agente

[![Caixa do agente](guia/assets/banner.jpg)](https://inematds.github.io/caixa-do-agente/guia/)

**🇧🇷 [Português](README.md) · 🇺🇸 [English](README.en.md) · 🇪🇸 [Español](README.es.md)**


## 🎬 Assista ao vídeo

**A China trouxe nova mensagem: o fim dos agentes**: https://www.youtube.com/watch?v=XX_yzA8xyt0 · versão vertical: https://www.youtube.com/watch?v=9LB89_ImgPo

**Seu agente de IA lê suas senhas: a caixa do agente em palavras simples**: https://www.youtube.com/watch?v=PiBmzECMBrk

## O que é

A caixa-do-agente é um kit gratuito do INEMA para quem já usa agentes de IA no computador (Claude Code, Codex,
DeepSeek Harness) e quer que eles trabalhem com segurança. A ideia vem do que a DeepSeek mostrou: **modelo +
harness = agente**, e o que faz o agente render é o harness, com o trabalho rodando numa caixa que nasce, executa
e é destruída. O kit traz o `caixa.sh`, que roda qualquer agente ou comando numa caixa Docker descartável, sem
rede e sem os seus `.env`, e o `auditar.py`, que dá nota de 0 a 10 ao harness que você já usa. Você precisa de
Docker sem `sudo` e Python 3 (Linux; no macOS, `brew install coreutils`).

## 📖 Guia de uso

Guia completo (landing + passo a passo): **https://inematds.github.io/caixa-do-agente/guia/**

## Em 1 minuto

```bash
git clone https://github.com/inematds/caixa-do-agente && cd caixa-do-agente

# 1. nota do seu harness (só lê, não muda nada)
python3 auditar.py ~/meu-projeto

# 2. rodar algo numa caixa descartável: cria → roda → destrói
./caixa.sh ~/meu-projeto -- npm test

# 3. agente com a chave do modelo: só a variável pedida entra na caixa
./caixa.sh ~/meu-projeto --rede --env ANTHROPIC_API_KEY -- npx -y @anthropic-ai/claude-code -p "rode os testes" --dangerously-skip-permissions

# 4. provar que a caixa funciona (18 checagens)
bash testes/teste.sh
```

## O processo, do início ao fim

| # | Passo | Comando | Quem |
|---|---|---|---|
| 1 | Baixar o kit | `git clone https://github.com/inematds/caixa-do-agente` | você |
| 2 | Provar a caixa | `bash testes/teste.sh` → `TUDO OK (18/18)` | ⚙️ script |
| 3 | Nota do harness | `python3 auditar.py ~/meu-projeto` | ⚙️ script |
| 4 | Rodar na caixa | `./caixa.sh ~/meu-projeto -- <comando>` | ⚙️ script |
| 5 | Revisar o patch | `less caixa-*.patch` | você |
| 6 | Aplicar o que você leu (se quiser) | `cd ~/meu-projeto && patch -p1 < caixa-*.patch` | você |
| 7 | Fechar a camada que faltou | o kit que o auditor apontou | você |

## O ciclo da caixa

Ficam fora da cópia: `.env`, chaves e credenciais, `node_modules` e `.venv`. Agente com tela (login pela assinatura): `--interativo`.


| passo | o que acontece |
|---|---|
| **1. Criar** | cópia do projeto numa pasta temporária, **sem** `.env`, chaves `.pem`, `id_rsa`, `credentials*.json`… |
| **2. Caixa** | o comando roda num container **sem rede** (`--rede` libera), com teto de memória, CPU, processos e tempo, sem privilégios |
| **3. Destruir** | mostra quantos arquivos mudaram, salva um `.patch`, apaga o container e a cópia |

O projeto original só muda se você aplicar: `patch -p1 < caixa-….patch` dentro do projeto leva exatamente o que você leu. O `--aplicar` faz uma rodada NOVA e pergunta antes de copiar; leia o patch dessa rodada antes de responder `s` (com agente, cada rodada sai diferente).
O `--aplicar` copia arquivos novos e alterados; arquivo apagado dentro da caixa não é apagado no original.

## As 6 camadas que o auditor confere

| camada | o que olha | se faltar, veja |
|---|---|---|
| Caixa (sandbox) | sandbox do Claude Code, `sandbox_mode` do Codex, sandbox do dsh | `caixa.sh` · [rea-sem-travas](https://inematds.github.io/rea-sem-travas/guia/) |
| Aprovação | nenhum harness no modo "pula tudo" (`bypassPermissions`; Codex `never` + `danger-full-access`) | [agente-blindado](https://inematds.github.io/agente-blindado/guia/) |
| Travas fora do prompt | regras `deny` e ganchos `PreToolUse` | [agente-blindado](https://inematds.github.io/agente-blindado/guia/) |
| Verificação | testes no projeto, ganchos `Stop`/`PostToolUse` | [agente-que-aprende](https://inematds.github.io/agente-que-aprende/guia/) |
| Contexto e memória | `AGENTS.md`, `CLAUDE.md` | [memoria-projetos](https://inematds.github.io/memoria-projetos/guia/) |
| Segredos fora do alcance | `.env` e chaves dentro do projeto | `caixa.sh` |

## Mapa: os outros kits INEMA sobre harness

| quer… | kit |
|---|---|
| entender o que é harness (vídeo) | [ai-harness](https://inematds.github.io/ai-harness/) |
| curso rápido: terminal e harness | [agentes-harness](https://inematds.github.io/agentes-harness/) |
| curso completo de engenharia agêntica | [hardnessai](https://inematds.github.io/hardnessai/) |
| rodar o DeepSeek Harness local com modelo aberto | [rea-sem-travas](https://inematds.github.io/rea-sem-travas/guia/) |
| DeepSeek Harness + Codex + Claude Code no mesmo ambiente | [dsh-orchestrator](https://inematds.github.io/dsh-orchestrator/guia/) |
| modelo sem recusa no DeepSeek Harness, para segurança defensiva | [ia-sem-censura-defensiva](https://inematds.github.io/ia-sem-censura-defensiva/guia/) |
| travas contra injeção de prompt | [agente-blindado](https://inematds.github.io/agente-blindado/guia/) |
| gastar menos esforço do modelo | [esforco-certo](https://inematds.github.io/esforco-certo/guia/) |

## Os números da DeepSeek (fonte primária)

- **DeepSeek Harness (`dsh`)**: código aberto (MIT), arquitetura "tudo é plugin", em prévia para desenvolvedores;
  roda com `npx @deepseek-ai/dsh@latest web` — [github.com/deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness).
- **DSec**, a plataforma de caixas da DeepSeek: cerca de 3 milhões de sandboxes por dia por unidade de ~160
  máquinas, mais de 380 mil ao mesmo tempo e mais de 5 mil criadas por segundo, segundo a própria DeepSeek —
  [arXiv 2609.22978](https://arxiv.org/abs/2609.22978) (19/09/2026).

## Limites

- A caixa isola arquivos, rede e recursos com Docker; não é uma máquina virtual. Para código que você não confia
  de jeito nenhum, use uma VM.
- Com `--rede`, o agente pode mandar para fora o que estiver na cópia (os segredos já ficaram de fora).
- O auditor lê as configurações mais comuns; ele aponta caminhos, não garante segurança.

Projetos e cursos gratuitos: https://inema.club
