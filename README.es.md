# caixa-do-agente

[![Caja del agente](guia/assets/banner-es.jpg)](https://inematds.github.io/caixa-do-agente/guia/es/)

**🇧🇷 [Português](README.md) · 🇺🇸 [English](README.en.md) · 🇪🇸 [Español](README.es.md)**


## 🎬 Mira el video

**China trajo un nuevo mensaje: el fin de los agentes** (en portugués): https://www.youtube.com/watch?v=XX_yzA8xyt0 · versión vertical: https://www.youtube.com/watch?v=9LB89_ImgPo

**Tu agente de IA lee tus contraseñas: la caja del agente en palabras simples** (en portugués): https://www.youtube.com/watch?v=PiBmzECMBrk

## Qué es

La caixa-do-agente (caja del agente) es un kit gratuito de INEMA para quien ya usa agentes de IA en la computadora
(Claude Code, Codex, DeepSeek Harness) y quiere que trabajen con seguridad. La idea viene de lo que mostró DeepSeek:
**modelo + harness = agente**, y lo que hace rendir al agente es el harness, con el trabajo ejecutándose en una caja
que nace, ejecuta y se destruye. El kit trae `caixa.sh`, que ejecuta cualquier agente o comando en una caja Docker
desechable, sin red y sin tus `.env`, y `auditar.py`, que le pone nota de 0 a 10 al harness que ya usas. Necesitas
Docker sin `sudo` y Python 3 (Linux; en macOS, `brew install coreutils`).

## 📖 Guía de uso

Guía completa (landing + paso a paso): **https://inematds.github.io/caixa-do-agente/guia/es/**

## En 1 minuto

```bash
git clone https://github.com/inematds/caixa-do-agente && cd caixa-do-agente

# 1. nota de tu harness (solo lee, no cambia nada)
python3 auditar.py ~/meu-projeto

# 2. ejecutar algo en una caja desechable: crea → ejecuta → destruye
./caixa.sh ~/meu-projeto -- npm test

# 3. agente con la clave del modelo: solo la variable pedida entra en la caja
./caixa.sh ~/meu-projeto --rede --env ANTHROPIC_API_KEY -- npx -y @anthropic-ai/claude-code -p "rode os testes" --dangerously-skip-permissions

# 4. comprobar que la caja funciona (18 verificaciones)
bash testes/teste.sh
```

Los flags y la salida de los scripts están en portugués: `--aplicar` = aplicar, `--rede` = red, `--montar` = montar, `--interativo` = interactivo, `--memoria` = memoria, `--tempo` = tiempo, `--imagem` = imagen.

## El proceso, de principio a fin

| # | Paso | Comando | Quién |
|---|---|---|---|
| 1 | Descargar el kit | `git clone https://github.com/inematds/caixa-do-agente` | tú |
| 2 | Probar la caja | `bash testes/teste.sh` → `TUDO OK (18/18)` | ⚙️ script |
| 3 | Nota del harness | `python3 auditar.py ~/meu-projeto` | ⚙️ script |
| 4 | Ejecutar en la caja | `./caixa.sh ~/meu-projeto -- <cmd>` | ⚙️ script |
| 5 | Revisar el patch | `less caixa-*.patch` | tú |
| 6 | Aplicar lo que leíste (opcional) | `cd ~/meu-projeto && patch -p1 < caixa-*.patch` | tú |
| 7 | Cerrar la capa que falta | el kit que señaló el auditor | tú |

## El ciclo de la caja

Quedan fuera de la copia: `.env`, claves y credenciales, `node_modules` y `.venv`. Agente con pantalla (login con la suscripción): `--interativo`.

| paso | qué sucede |
|---|---|
| **1. Crear** | copia del proyecto en una carpeta temporal, **sin** `.env`, claves `.pem`, `id_rsa`, `credentials*.json`… |
| **2. Caja** | el comando se ejecuta en un contenedor **sin red** (`--rede` la habilita), con tope de memoria, CPU, procesos y tiempo, sin privilegios |
| **3. Destruir** | muestra cuántos archivos cambiaron, guarda un `.patch`, borra el contenedor y la copia |

El proyecto original solo cambia si aplicas: `patch -p1 < caixa-….patch` dentro del proyecto lleva exactamente lo que leíste. `--aplicar` hace una ejecución NUEVA y pregunta antes de copiar; lee el patch de esa ejecución antes de responder `s` (con un agente, cada ejecución sale distinta).
`--aplicar` copia archivos nuevos y modificados; un archivo borrado dentro de la caja no se borra en el original.

## Las 6 capas que revisa el auditor

| capa | qué mira | si falta, ve |
|---|---|---|
| Caja (sandbox) | sandbox de Claude Code, `sandbox_mode` de Codex, sandbox de dsh | `caixa.sh` · [rea-sem-travas](https://inematds.github.io/rea-sem-travas/guia/) |
| Aprobación | ningún harness en modo "saltar todo" (`bypassPermissions`; Codex `never` + `danger-full-access`) | [agente-blindado](https://inematds.github.io/agente-blindado/guia/) |
| Bloqueos fuera del prompt | reglas `deny` y hooks `PreToolUse` | [agente-blindado](https://inematds.github.io/agente-blindado/guia/) |
| Verificación | pruebas en el proyecto, hooks `Stop`/`PostToolUse` | [agente-que-aprende](https://inematds.github.io/agente-que-aprende/guia/) |
| Contexto y memoria | `AGENTS.md`, `CLAUDE.md` | [memoria-projetos](https://inematds.github.io/memoria-projetos/guia/) |
| Secretos fuera de alcance | `.env` y claves dentro del proyecto | `caixa.sh` |

## Mapa: los otros kits INEMA sobre harness

| quieres… | kit |
|---|---|
| entender qué es un harness (video) | [ai-harness](https://inematds.github.io/ai-harness/) |
| curso rápido: terminal y harness | [agentes-harness](https://inematds.github.io/agentes-harness/) |
| curso completo de ingeniería agéntica | [hardnessai](https://inematds.github.io/hardnessai/) |
| ejecutar DeepSeek Harness local con modelo abierto | [rea-sem-travas](https://inematds.github.io/rea-sem-travas/guia/) |
| DeepSeek Harness + Codex + Claude Code en el mismo entorno | [dsh-orchestrator](https://inematds.github.io/dsh-orchestrator/guia/) |
| modelo sin rechazos en DeepSeek Harness, para seguridad defensiva | [ia-sem-censura-defensiva](https://inematds.github.io/ia-sem-censura-defensiva/guia/) |
| bloqueos contra inyección de prompt | [agente-blindado](https://inematds.github.io/agente-blindado/guia/) |
| gastar menos esfuerzo del modelo | [esforco-certo](https://inematds.github.io/esforco-certo/guia/) |

## Los números de DeepSeek (fuente primaria)

- **DeepSeek Harness (`dsh`)**: código abierto (MIT), arquitectura "todo es plugin", en vista previa para desarrolladores;
  se ejecuta con `npx @deepseek-ai/dsh@latest web` — [github.com/deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness).
- **DSec**, la plataforma de cajas de DeepSeek: cerca de 3 millones de sandboxes por día por unidad de ~160
  máquinas, más de 380 mil al mismo tiempo y más de 5 mil creadas por segundo, según la propia DeepSeek —
  [arXiv 2609.22978](https://arxiv.org/abs/2609.22978) (19/09/2026).

## Límites

- La caja aísla archivos, red y recursos con Docker; no es una máquina virtual. Para código en el que no confías
  en absoluto, usa una VM.
- Con `--rede`, el agente puede enviar hacia afuera lo que esté en la copia (los secretos ya quedaron fuera).
- El auditor lee las configuraciones más comunes; señala caminos, no garantiza seguridad.

Proyectos y cursos gratuitos: https://inema.club
