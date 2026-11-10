#!/usr/bin/env bash
# Prova que a caixa cumpre o que promete. Uso: bash testes/teste.sh   (precisa de Docker)
set -u
cd "$(dirname "$0")/.."
F=0; ok(){ echo "OK  $*"; }; ruim(){ echo "FALHOU  $*"; F=$((F+1)); }
P=$(mktemp -d); trap 'rm -rf "$P" caixa-*.patch' EXIT
echo "CHAVE=segredo123" > "$P/.env"; echo "-----BEGIN KEY-----" > "$P/id.pem"; echo "ola" > "$P/app.txt"
IMG=node:22-slim
SAIDA=$(./caixa.sh "$P" --imagem $IMG -- sh -c 'ls -a; cat .env 2>&1; node -e "require(\"https\").get(\"https://example.com\",()=>console.log(\"REDE_ABERTA\")).on(\"error\",()=>console.log(\"REDE_FECHADA\"))"; echo mudou > app.txt; echo novo > novo.txt' 2>&1)
echo "$SAIDA" | sed 's/^/    /'
echo "$SAIDA" | grep -q 'segredo123' && ruim ".env entrou na caixa" || ok ".env ficou fora"
echo "$SAIDA" | grep -q 'id.pem' && ruim "chave .pem entrou na caixa" || ok "chave .pem ficou fora"
echo "$SAIDA" | grep -q 'REDE_FECHADA' && ok "sem rede por padrão" || ruim "rede não estava fechada"
[ "$(cat "$P/app.txt")" = "ola" ] && ok "projeto original intacto" || ruim "original foi alterado sem --aplicar"
[ ! -e "$P/novo.txt" ] && ok "arquivo novo não vazou para o original" || ruim "novo.txt apareceu no original"
echo "$SAIDA" | grep -q '2 arquivo(s) mudaram' && ok "mudanças contadas (2)" || ruim "contagem de mudanças errada"
ls caixa-*.patch >/dev/null 2>&1 && grep -q '+mudou' caixa-*.patch && ok "patch salvo com a mudança" || ruim "patch ausente"
docker ps -a --format '{{.Names}}' | grep -q '^caixa-' && ruim "sobrou container caixa-*" || ok "container destruído"
./caixa.sh "$P" --imagem $IMG --aplicar --sim -- sh -c 'echo aplicado > app.txt' >/dev/null 2>&1
[ "$(cat "$P/app.txt")" = "aplicado" ] && ok "--aplicar copia de volta" || ruim "--aplicar não aplicou"
[ "$(cat "$P/.env")" = "CHAVE=segredo123" ] && ok ".env do original preservado após --aplicar" || ruim ".env do original mudou"
# auditor
python3 auditar.py "$P" --json > "$P/a.json" && python3 -c "import json;d=json.load(open('$P/a.json'));assert 0<=d['nota']<=10 and len(d['itens'])==6;s=[i for i in d['itens'] if i['chave']=='segredos'][0];assert s['pontos']<2" && ok "auditor: nota e segredos detectados" || ruim "auditor"
# --env repassa só a variável pedida
export CAIXA_TESTE_A=valorA CAIXA_TESTE_B=valorB
SE=$(./caixa.sh "$P" --imagem $IMG --env CAIXA_TESTE_A -- sh -c 'echo "A=${CAIXA_TESTE_A:-} B=${CAIXA_TESTE_B:-}"' 2>&1)
echo "$SE" | grep -q 'A=valorA B=$' && ok "--env repassa só a variável pedida" || ruim "--env"
# auditor: sandbox: false não conta; sem harness, Caixa e Aprovação zeram
H=$(mktemp -d); mkdir -p "$H/.dsh"; echo 'sandbox: false' > "$H/.dsh/settings.yaml"
HOME="$H" python3 auditar.py "$H" | grep -q '^\[FALTA\] Caixa' && ok "auditor: sandbox: false = FALTA" || ruim "auditor sandbox false"
rm -rf "$H/.dsh"
HOME="$H" python3 auditar.py "$H" --json | python3 -c "import json,sys;d=json.load(sys.stdin);p={i['chave']:i['pontos'] for i in d['itens']};assert p['caixa']==0 and p['aprovacao']==0" && ok "auditor: sem harness, caixa e aprovação = 0" || ruim "auditor sem harness"
rm -rf "$H"
# --interativo dá um terminal de verdade à caixa (agente com tela)
if command -v script >/dev/null; then
  echo | timeout 60 script -qec "./caixa.sh '$P' --imagem $IMG --interativo --tempo 20 -- tty" /dev/null 2>&1 | grep -aq '/dev/pts' && ok "--interativo abre terminal" || ruim "--interativo"
else ok "--interativo (pulado: sem o comando script)"; fi
# cache e dependências criados na caixa não contam nem voltam
./caixa.sh "$P" --imagem $IMG --aplicar --sim -- sh -c 'mkdir -p node_modules/x __pycache__ && echo a > node_modules/x/i.js && echo b > __pycache__/m.pyc' > "$P.log" 2>&1
grep -q '0 arquivo(s) mudaram' "$P.log" && [ ! -e "$P/node_modules" ] && [ ! -e "$P/__pycache__" ] && ok "node_modules/__pycache__ não voltam" || ruim "cache voltou ou contou"; rm -f "$P.log"
./caixa.sh --help | grep -q 'Uso:' && ok "--help mostra a ajuda" || ruim "--help"
echo; [ $F -eq 0 ] && echo "TUDO OK (17/17)" || { echo "$F falha(s)"; exit 1; }
