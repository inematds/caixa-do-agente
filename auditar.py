#!/usr/bin/env python3
"""auditar.py — dá nota (0 a 10) ao HARNESS do seu agente, não ao modelo.

Lê, sem alterar nada, as configurações que existirem na máquina:
  Claude Code  ~/.claude/settings.json e <projeto>/.claude/settings*.json
  Codex        ~/.codex/config.toml
  DeepSeek Harness (dsh)  ~/.dsh/settings.yaml e <projeto>/.dsh/settings.yaml
e o próprio projeto (AGENTS.md/CLAUDE.md, testes, segredos soltos).

Uso:  python3 auditar.py [pasta-do-projeto] [--json]

Camadas (2 = OK, 1 = MEIO, 0 = FALTA; nota = soma / 12 x 10):
  Caixa       sandbox ligado no Claude Code, no Codex (read-only/workspace-write) ou no dsh
  Aprovação   há harness e nenhum roda em modo "pula tudo" (bypassPermissions; Codex never + danger-full-access)
  Travas      regras deny (o que o agente nunca pode) + ganchos PreToolUse (script que barra antes de agir)
  Verificação testes no projeto + ganchos Stop/PostToolUse (script que confere depois de agir)
  Contexto    AGENTS.md / CLAUDE.md / GEMINI.md no projeto
  Segredos    nenhum .env, chave ou credencial dentro da pasta do projeto
Caixa, Aprovação e Travas vêm da configuração GLOBAL (~/.claude, ~/.codex, ~/.dsh) somada à do projeto.
"""
import fnmatch, json, os, re, sys
from pathlib import Path

HOME = Path.home()
SEGREDOS = ['.env', '.env.*', '*.pem', '*.key', 'id_rsa*', 'id_ed25519*', '*.p12', 'credentials*.json',
            'service-account*.json', '.netrc', '.npmrc', '.pypirc', 'token*.json', 'secrets.json', 'secrets.yaml', 'secrets.yml', 'secrets.toml', 'secrets.env', '.secrets']
KITS = {
    'caixa': 'caixa.sh deste kit; DeepSeek Harness em container: rea-sem-travas (https://inematds.github.io/rea-sem-travas/guia/)',
    'aprovacao': 'agente-blindado — aprovação antes de ação destrutiva (https://inematds.github.io/agente-blindado/guia/)',
    'travas': 'agente-blindado — 5 travas fora do prompt (https://inematds.github.io/agente-blindado/guia/)',
    'verificacao': 'agente-que-aprende — lição vira trava (https://inematds.github.io/agente-que-aprende/guia/)',
    'contexto': 'memoria-projetos (https://inematds.github.io/memoria-projetos/guia/)',
    'segredos': 'caixa.sh deste kit (deixa .env e chaves fora da caixa)',
    'plugins': 'DeepSeek Harness: tudo é plugin (https://github.com/deepseek-ai/deepseek-harness)',
}


def ler_json(p):
    try:
        return json.loads(Path(p).read_text())
    except Exception:
        return None


def ler_txt(p):
    try:
        return Path(p).read_text(errors='ignore')
    except Exception:
        return ''


def segredos_no_projeto(proj, limite=2000):
    achados = []
    for raiz, dirs, arqs in os.walk(proj):
        dirs[:] = [d for d in dirs if d not in ('node_modules', '.git', '.venv', 'venv', '__pycache__')]
        for a in arqs:
            if any(fnmatch.fnmatch(a, s) for s in SEGREDOS) and not a.endswith(('.example', '.exemplo', '.sample')):
                achados.append(os.path.relpath(os.path.join(raiz, a), proj))
        if len(achados) >= limite:
            break
    return achados


def auditar(proj):
    proj = Path(proj).resolve()
    harness = []
    # --- Claude Code
    cc = [HOME / '.claude/settings.json', proj / '.claude/settings.json', proj / '.claude/settings.local.json']
    cc_cfg = [c for c in (ler_json(p) for p in cc) if isinstance(c, dict)]
    perms = {}
    hooks = {}
    sandbox_cc = False
    for c in cc_cfg:
        for k, v in (c.get('permissions') or {}).items():
            perms.setdefault(k, v if not isinstance(v, list) else [])
            if isinstance(v, list):
                perms[k] = perms[k] + v
        for k, v in (c.get('hooks') or {}).items():
            hooks[k] = hooks.get(k, 0) + (len(v) if isinstance(v, list) else 1)
        sb = c.get('sandbox')
        if isinstance(sb, dict) and sb.get('enabled'):
            sandbox_cc = True
    if cc_cfg:
        harness.append('Claude Code')
    # --- Codex
    cx = ler_txt(HOME / '.codex/config.toml')
    cx_sandbox = re.search(r'^\s*sandbox_mode\s*=\s*"([^"]+)"', cx, re.M)
    cx_aprov = re.search(r'^\s*approval_policy\s*=\s*"([^"]+)"', cx, re.M)
    if cx:
        harness.append('Codex')
    # --- dsh
    dsh = ler_txt(HOME / '.dsh/settings.yaml') + ler_txt(proj / '.dsh/settings.yaml')
    if dsh:
        harness.append('DeepSeek Harness')
    # sandbox do dsh: chave "sandbox..." com valor que não seja desligado
    dsh_sb = False
    for m in re.finditer(r'^\s*sandbox[\w-]*\s*:\s*(\S.*)?$', dsh, re.M):
        v = (m.group(1) or 'sim').strip().strip('"\'').lower()
        if v not in ('false', 'off', 'no', 'none', 'disabled', 'danger-full-access', '0', '~', 'null'):
            dsh_sb = True

    itens = []

    def item(chave, nome, ok, meio, detalhe):
        pts = 2 if ok else (1 if meio else 0)
        itens.append({'chave': chave, 'camada': nome, 'pontos': pts, 'detalhe': detalhe,
                      'proximo': None if ok else KITS.get(chave)})

    # 1. caixa (sandbox)
    cx_modo = cx_sandbox.group(1) if cx_sandbox else None
    caixa_ok = sandbox_cc or (cx_modo in ('read-only', 'workspace-write')) or dsh_sb
    item('caixa', 'Caixa (sandbox)', caixa_ok, False,
         f"Claude Code sandbox={'ligado' if sandbox_cc else 'desligado'}; Codex sandbox_mode={cx_modo or '—'}"
         + (f"; dsh sandbox={'ligado' if dsh_sb else 'desligado'}" if dsh else ''))
    # 2. aprovação
    modo = perms.get('defaultMode')
    perigoso = modo == 'bypassPermissions' or (cx_aprov and cx_aprov.group(1) == 'never' and cx_modo == 'danger-full-access')
    tem = bool(harness)
    item('aprovacao', 'Aprovação (quem confirma)', tem and not perigoso, False,
         f"Claude Code defaultMode={modo or 'padrão'}; Codex approval_policy={cx_aprov.group(1) if cx_aprov else '—'}")
    # 3. travas fora do prompt (deny + PreToolUse)
    deny = len(perms.get('deny') or [])
    pre = hooks.get('PreToolUse', 0)
    item('travas', 'Travas fora do prompt', deny > 0 and pre > 0, deny > 0 or pre > 0,
         f"{deny} regra(s) deny; {pre} gancho(s) PreToolUse")
    # 4. verificação
    testes = any((proj / t).exists() for t in ('tests', 'testes', 'test', 'package.json', 'pytest.ini', 'Makefile'))
    stop = hooks.get('Stop', 0) + hooks.get('PostToolUse', 0)
    item('verificacao', 'Verificação (prova do trabalho)', testes and stop > 0, testes or stop > 0,
         f"testes no projeto={'sim' if testes else 'não'}; ganchos Stop/PostToolUse={stop}")
    # 5. contexto
    ctx = [n for n in ('AGENTS.md', 'CLAUDE.md', 'GEMINI.md') if (proj / n).exists()]
    item('contexto', 'Contexto e memória', bool(ctx), False, f"arquivos de instrução: {', '.join(ctx) or 'nenhum'}")
    # 6. segredos ao alcance
    seg = segredos_no_projeto(proj)
    exposto = seg and not caixa_ok
    item('segredos', 'Segredos fora do alcance', not seg, not exposto,
         f"{len(seg)} arquivo(s) de segredo dentro do projeto" + (f" (ex.: {seg[0]})" if seg else ''))
    # bônus de plugins não entra na nota; vira dica
    nota = round(sum(i['pontos'] for i in itens) / (2 * len(itens)) * 10, 1)
    return {'projeto': str(proj), 'harness_encontrados': harness, 'nota': nota, 'itens': itens}


def main():
    if '-h' in sys.argv or '--help' in sys.argv:
        print(__doc__.strip()); return
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    if args and not os.path.isdir(args[0]):
        print(f'pasta não existe: {args[0]}', file=sys.stderr); sys.exit(2)
    r = auditar(args[0] if args else '.')
    if '--json' in sys.argv:
        print(json.dumps(r, ensure_ascii=False, indent=2))
        return
    print(f"Harness encontrados: {', '.join(r['harness_encontrados']) or 'nenhum (sem Claude Code, Codex ou dsh configurado)'}")
    print(f"Projeto: {r['projeto']}\n")
    for i in r['itens']:
        marca = {2: '[OK]   ', 1: '[MEIO] ', 0: '[FALTA]'}[i['pontos']]
        print(f"{marca} {i['camada']}: {i['detalhe']}")
        if i['proximo']:
            print(f"    → {i['proximo']}")
    print(f"\nNOTA DO HARNESS: {r['nota']}/10  (o modelo não entra na conta)")
    print("Critério: cada camada vale 2 (OK), 1 (MEIO) ou 0 (FALTA); nota = soma / 12 × 10.")


if __name__ == '__main__':
    main()
