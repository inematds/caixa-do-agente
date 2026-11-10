#!/usr/bin/env bash
# caixa.sh — roda um agente (ou qualquer comando) numa CAIXA descartável:
#   1. CRIAR    copia o projeto para uma pasta temporária, sem segredos (.env, chaves, credenciais)
#   2. CAIXA    roda o comando num container Docker sem rede, com teto de memória e CPU
#   3. DESTRUIR mostra o que mudou, apaga o container e a cópia
# O projeto original só muda se você pedir (--aplicar).
#
# Uso:
#   ./caixa.sh <pasta-do-projeto> [opções] -- <comando...>
# Opções:
#   --imagem IMG     imagem Docker (padrão: node:22-slim)
#   --rede           libera a rede (padrão: sem rede nenhuma)
#   --memoria 4g     teto de memória (padrão 4g)
#   --cpus 2         teto de CPU (padrão 2)
#   --tempo 1800     teto de tempo em segundos (padrão 1800)
#   --aplicar        copia as mudanças de volta para o projeto (pede confirmação)
#   --sim            com --aplicar, não pergunta
#   --env NOME       repassa SÓ esta variável do seu terminal para a caixa (repetível; ex.: a chave do modelo)
#   --montar O:D[:ro] monta a pasta O do seu computador em D na caixa (repetível; use :ro = só leitura)
#   --patch PASTA    onde salvar o .patch (padrão: a pasta atual)
#   --interativo     abre o terminal da caixa (para agente com tela: claude, codex, dsh tui, login)
# Exemplos:
#   ./caixa.sh ~/meu-app -- npm test
#   ./caixa.sh ~/meu-app --rede -- npx -y @deepseek-ai/dsh@latest --help
#   ./caixa.sh ~/meu-app --rede --env ANTHROPIC_API_KEY -- npx -y @anthropic-ai/claude-code -p "rode os testes e corrija" --dangerously-skip-permissions
# Linux. No macOS: brew install coreutils (traz o gtimeout). Docker sem sudo (usuário no grupo docker).
# node_modules, .venv e caches não voltam para o original nem entram no patch.
set -euo pipefail

IMAGEM=node:22-slim REDE=0 MEM=4g CPUS=2 TEMPO=1800 APLICAR=0 SIM=0
ENVS=() MONTS=() PATCHDIR=$PWD IT=0
case "${1:-}" in ''|-h|--help) sed -n '2,/^set -e/p' "$0" | grep '^#' | sed 's/^# \{0,1\}//'; [ $# -ge 1 ]; exit $?;; esac
PROJ=$(cd "$1" && pwd); shift
while [ $# -gt 0 ]; do
  case "$1" in
    --imagem) IMAGEM=$2; shift 2;;
    --rede) REDE=1; shift;;
    --memoria) MEM=$2; shift 2;;
    --cpus) CPUS=$2; shift 2;;
    --tempo) TEMPO=$2; shift 2;;
    --aplicar) APLICAR=1; shift;;
    --sim) SIM=1; shift;;
    --env) [ -n "${!2:-}" ] || { echo "variável $2 vazia ou inexistente no seu terminal" >&2; exit 1; }; ENVS+=(-e "$2"); shift 2;;
    --montar) MONTS+=(-v "$2"); shift 2;;
    --interativo) IT=1; shift;;
    --patch) PATCHDIR=$(cd "$2" && pwd); shift 2;;
    --) shift; break;;
    *) echo "opção desconhecida: $1" >&2; exit 1;;
  esac
done
[ $# -ge 1 ] || { echo "falta o comando depois de --" >&2; exit 1; }
command -v docker >/dev/null || { echo "precisa do Docker" >&2; exit 1; }
TO=$(command -v timeout || command -v gtimeout || true)
[ -n "$TO" ] || { echo "precisa do comando timeout (no macOS: brew install coreutils)" >&2; exit 1; }

# Segredos que nunca entram na caixa (mesma lista do auditar.py)
SEGREDOS=('.env' '.env.*' '*.pem' '*.key' 'id_rsa*' 'id_ed25519*' '*.p12' 'credentials*.json'
          'service-account*.json' '.netrc' '.npmrc' '.pypirc' 'token*.json' 'secrets.*')

T0=$(date +%s)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/caixa.XXXXXX")
NOME="caixa-$(basename "$TMP" | cut -d. -f2 | tr 'A-Z' 'a-z')"
limpar() { docker rm -f "$NOME" >/dev/null 2>&1 || true; rm -rf "$TMP"; }
trap limpar EXIT

echo "▶ 1/3 CRIAR   cópia de $PROJ (sem segredos)"
EXC=(); for s in "${SEGREDOS[@]}"; do EXC+=(--exclude="$s"); done
rsync -a "${EXC[@]}" --exclude=node_modules --exclude=.venv --exclude="caixa-*.patch" "$PROJ"/ "$TMP/antes"/
cp -a "$TMP/antes" "$TMP/trabalho"
FORA=$(cd "$PROJ" && for s in "${SEGREDOS[@]}"; do find . -path ./node_modules -prune -o -name "$s" -type f -print; done | sort -u | wc -l)
echo "  $FORA arquivo(s) de segredo ficaram de fora"

ARGS=(--name "$NOME" --rm=false -w /trabalho -v "$TMP/trabalho:/trabalho"
      --memory "$MEM" --memory-swap "$MEM" --cpus "$CPUS" --pids-limit 512
      --cap-drop ALL --security-opt no-new-privileges --user "$(id -u):$(id -g)" -e HOME=/tmp)
[ "$REDE" = 1 ] || ARGS+=(--network none)
ARGS+=(${ENVS[@]+"${ENVS[@]}"} ${MONTS[@]+"${MONTS[@]}"})
[ "$IT" = 1 ] && ARGS+=(-it)
[ ${#ENVS[@]} -eq 0 ] || echo "  variáveis repassadas: $(printf '%s ' "${ENVS[@]}" | sed 's/-e //g')"
[ ${#MONTS[@]} -eq 0 ] || echo "  pastas montadas: $(printf '%s ' "${MONTS[@]}" | sed 's/-v //g')"
echo "▶ 2/3 CAIXA   $IMAGEM · rede $([ "$REDE" = 1 ] && echo LIGADA || echo desligada) · $MEM · $CPUS CPU · ${TEMPO}s"
set +e
"$TO" $([ "$IT" = 1 ] && echo --foreground) "$TEMPO" docker run "${ARGS[@]}" "$IMAGEM" "$@"
RC=$?
set -e
echo "  saída do comando: $RC"

echo "▶ 3/3 DESTRUIR"
# o que nunca volta nem conta como mudança: dependências e cache
IGN=(node_modules .venv __pycache__ '*.pyc' .npm .cache .git)
DX=(); RX=(); for i in "${IGN[@]}"; do DX+=(-x "$i"); RX+=(--exclude="$i"); done
MUD=$(diff -rq "${DX[@]}" "$TMP/antes" "$TMP/trabalho" 2>/dev/null | wc -l || true)
echo "  $MUD arquivo(s) mudaram dentro da caixa"
if [ "$MUD" -gt 0 ]; then
  (cd "$TMP" && diff -ruN "${DX[@]}" antes trabalho > "$TMP/mudancas.patch" || true)
  PF="$PATCHDIR/caixa-$(date +%Y%m%d-%H%M%S).patch"
  cp "$TMP/mudancas.patch" "$PF"
  echo "  patch salvo (o diff de tudo que mudou): $PF"
  if [ "$APLICAR" = 1 ]; then
    r=s; [ "$SIM" = 1 ] || read -r -p "  aplicar no projeto original? (s/N) " r
    if [ "$r" = s ]; then rsync -a "${RX[@]}" "$TMP/trabalho"/ "$PROJ"/; echo "  aplicado em $PROJ"; fi
  fi
fi
docker rm -f "$NOME" >/dev/null 2>&1 || true
docker ps -a --format '{{.Names}}' | grep -qx "$NOME" && echo "  ATENÇÃO: container ainda existe" || echo "  container apagado · cópia apagada"
echo "■ fim em $(( $(date +%s) - T0 ))s"
exit $RC
