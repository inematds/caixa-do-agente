# caixa-do-agente

[![Agent Box](guia/assets/banner-en.jpg)](https://inematds.github.io/caixa-do-agente/guia/en/)

**🇧🇷 [Português](README.md) · 🇺🇸 [English](README.en.md) · 🇪🇸 [Español](README.es.md)**

## What it is

caixa-do-agente (Agent Box) is a free INEMA kit for people who already use AI agents on their computer (Claude Code,
Codex, DeepSeek Harness) and want them to work safely. The idea comes from what DeepSeek showed: **model +
harness = agent**, and what makes the agent perform is the harness, with the work running in a box that is created,
executes and is destroyed. The kit includes `caixa.sh`, which runs any agent or command in a disposable Docker box,
with no network and without your `.env` files, and `auditar.py`, which scores the harness you already use from 0 to
10. You need Docker and Python 3 (Linux; on macOS, `brew install coreutils`).

## 📖 User guide

Full guide (landing + step by step): **https://inematds.github.io/caixa-do-agente/guia/en/**

## In 1 minute

```bash
git clone https://github.com/inematds/caixa-do-agente && cd caixa-do-agente

# 1. score your harness (read-only, changes nothing)
python3 auditar.py ~/meu-projeto

# 2. run something in a disposable box: create → run → destroy
./caixa.sh ~/meu-projeto -- npm test

# 3. agent with the model key: only the requested variable goes into the box
./caixa.sh ~/meu-projeto --rede --env ANTHROPIC_API_KEY -- npx -y @anthropic-ai/claude-code -p "rode os testes" --dangerously-skip-permissions

# 4. prove the box works (15 checks)
bash testes/teste.sh
```

Flags and script output are in Portuguese: `--aplicar` = apply, `--rede` = network, `--montar` = mount, `--interativo` = interactive, `--memoria` = memory, `--tempo` = time, `--imagem` = image.

## The process, start to finish

| # | Step | Command | Who |
|---|---|---|---|
| 1 | Get the kit | `git clone https://github.com/inematds/caixa-do-agente` | you |
| 2 | Prove the box | `bash testes/teste.sh` → `TUDO OK (15/15)` | ⚙️ script |
| 3 | Score the harness | `python3 auditar.py ~/meu-projeto` | ⚙️ script |
| 4 | Run in the box | `./caixa.sh ~/meu-projeto -- <cmd>` | ⚙️ script |
| 5 | Review the patch | `less caixa-*.patch` | you |
| 6 | Apply (optional) | `./caixa.sh ~/meu-projeto --aplicar -- <cmd>` | you |
| 7 | Close the missing layer | the kit the auditor pointed to | you |

## The box cycle

Left out of the copy: `.env`, keys and credentials, `node_modules` and `.venv`. Agent with a screen (subscription login): `--interativo`.

| step | what happens |
|---|---|
| **1. Create** | copy of the project in a temporary folder, **without** `.env`, `.pem` keys, `id_rsa`, `credentials*.json`… |
| **2. Box** | the command runs in a container **with no network** (`--rede` enables it), with memory, CPU, process and time limits, without privileges |
| **3. Destroy** | shows how many files changed, saves a `.patch`, deletes the container and the copy |

The original project only changes with `--aplicar` (asks for confirmation). The `.patch` stays for you to review first.
`--aplicar` copies new and changed files; a file deleted inside the box is not deleted in the original.

## The 6 layers the auditor checks

| layer | what it looks at | if missing, see |
|---|---|---|
| Box (sandbox) | Claude Code sandbox, Codex `sandbox_mode`, dsh sandbox | `caixa.sh` · [rea-sem-travas](https://inematds.github.io/rea-sem-travas/guia/) |
| Approval | Claude Code `defaultMode`, Codex `approval_policy` | [agente-blindado](https://inematds.github.io/agente-blindado/guia/) |
| Guardrails outside the prompt | `deny` rules and `PreToolUse` hooks | [agente-blindado](https://inematds.github.io/agente-blindado/guia/) |
| Verification | tests in the project, `Stop`/`PostToolUse` hooks | [agente-que-aprende](https://inematds.github.io/agente-que-aprende/guia/) |
| Context and memory | `AGENTS.md`, `CLAUDE.md` | [memoria-projetos](https://inematds.github.io/memoria-projetos/guia/) |
| Secrets out of reach | `.env` and keys inside the project | `caixa.sh` |

## Map: the other INEMA kits about harnesses

| want to… | kit |
|---|---|
| understand what a harness is (video) | [ai-harness](https://inematds.github.io/ai-harness/) |
| quick course: terminal and harness | [agentes-harness](https://inematds.github.io/agentes-harness/) |
| complete course on agentic engineering | [hardnessai](https://inematds.github.io/hardnessai/) |
| run DeepSeek Harness locally with an open model | [rea-sem-travas](https://inematds.github.io/rea-sem-travas/guia/) |
| DeepSeek Harness + Codex + Claude Code in the same environment | [dsh-orchestrator](https://inematds.github.io/dsh-orchestrator/guia/) |
| a model with no refusals in DeepSeek Harness, for defensive security | [ia-sem-censura-defensiva](https://inematds.github.io/ia-sem-censura-defensiva/guia/) |
| guardrails against prompt injection | [agente-blindado](https://inematds.github.io/agente-blindado/guia/) |
| spend less model effort | [esforco-certo](https://inematds.github.io/esforco-certo/guia/) |

## DeepSeek's numbers (primary source)

- **DeepSeek Harness (`dsh`)**: open source (MIT), "everything is a plugin" architecture, in developer preview;
  runs with `npx @deepseek-ai/dsh@latest web` — [github.com/deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness).
- **DSec**, DeepSeek's box platform: about 3 million sandboxes per day per unit of ~160 machines, more than 380
  thousand at the same time and more than 5 thousand created per second, according to DeepSeek itself —
  [arXiv 2609.22978](https://arxiv.org/abs/2609.22978) (09/19/2026).

## Limits

- The box isolates files, network and resources with Docker; it is not a virtual machine. For code you don't trust
  at all, use a VM.
- With `--rede`, the agent can send out whatever is in the copy (the secrets were already left out).
- The auditor reads the most common settings; it points the way, it does not guarantee security.

Free projects and courses: https://inema.club
