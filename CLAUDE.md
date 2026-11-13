# CLAUDE.md — caixa-do-agente

Kit público (inematds/caixa-do-agente, autor dos commits `inematds <inematds@gmail.com>`).

- `caixa.sh` — roda comando/agente em container descartável (sem rede, sem segredos, tetos). Lista de segredos igual à do `auditar.py`: mudou uma, mude a outra.
- `auditar.py` — só lê configurações; nunca escrever nada na máquina do usuário.
- Antes de commitar: `bash testes/teste.sh` → `TUDO OK (18/18)`.
- Guia em `guia/` (PT) + `guia/en/` + `guia/es/`; README em 3 idiomas. Mudou o PT, retraduza os dois.
- Origem: vídeo "A China trouxe nova mensagem: o fim dos agentes" (lives4, 10/11/2026). Sem citar o vídeo de referência.

## Self-learning

Quando eu for corrigido ou perceber um erro: antes de seguir, acrescente a lição como regra de uma linha no TOPO de `## Lessons`.

## Lessons
- `--aplicar` é uma rodada NOVA (não aplica o patch lido): ensinar `patch -p1 < caixa-….patch` para levar exatamente o que foi revisado; o revisor do curso intelecto-v2 pegou o guia dizendo "leia o patch e aplique com --aplicar". (13/11/2026)
- Padrão `secrets.*` excluía o módulo `secrets.py` (código) da cópia e quebrava projeto Python na caixa: lista de segredos só com extensões de dado (`secrets.json/.yaml/.yml/.toml/.env`, `.secrets`); teste 18. (12/11/2026)
- `npx @deepseek-ai/dsh` sem tag falha (só há versões de prévia): usar `@deepseek-ai/dsh@latest`. (10/11/2026)
