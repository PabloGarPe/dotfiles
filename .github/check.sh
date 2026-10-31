#!/usr/bin/env bash
# Comprobaciones del repo antes de hacer push: 'dots check' (alias de git que pone install.sh).
# También lo ejecuta GitHub Actions (.github/workflows/check.yml) en cada push.
#
#   - Sintaxis de scripts: bash -n, shellcheck (errores), luac -p, python -m py_compile
#   - Ningún fichero con rutas de un usuario concreto (/home/<usuario>)
#   - Ningún fichero local o generado (.github/exclude) dentro del repo
#   - Si se ejecuta dentro de Hyprland: la config carga sin errores
#
# Sale con código 1 si algo falla.

set -uo pipefail

# Con 'dots check' git ya trae GIT_DIR y el directorio de trabajo; en un clon normal (CI), el repo actual
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME")" || exit 1

fails=0
ok()   { printf '\e[32m✓\e[0m %s\n' "$*"; }
bad()  { printf '\e[31m✗\e[0m %s\n' "$*"; fails=$((fails + 1)); }
skip() { printf '\e[33m–\e[0m %s\n' "$*"; }
indent() { sed 's/^/    /'; }

mapfile -t files < <(git ls-files)

# Scripts de shell: por extensión o por shebang
shells=()
for f in "${files[@]}"; do
    [[ -f $f ]] || continue
    case $f in
        *.sh|*.bash) shells+=("$f") ;;
        *.*) ;;
        *) head -c 64 "$f" 2>/dev/null | grep -qE '^#!.*\b(ba)?sh\b' && shells+=("$f") ;;
    esac
done

# 1. bash -n
out=$(for f in "${shells[@]}"; do bash -n "$f" 2>&1; done)
[[ -z $out ]] && ok "bash -n (${#shells[@]} scripts)" || { bad "bash -n"; indent <<<"$out"; }

# 2. shellcheck, solo errores (los avisos de estilo de scripts de terceros no bloquean)
if command -v shellcheck >/dev/null; then
    out=$(shellcheck -S error -f gcc "${shells[@]}" 2>&1)
    [[ -z $out ]] && ok "shellcheck" || { bad "shellcheck"; indent <<<"$out"; }
else
    skip "shellcheck no está instalado (sudo pacman -S shellcheck)"
fi

# 3. Lua (config de Hyprland, nvim)
luac=$(command -v luac5.4 || command -v luac || true)
mapfile -t luas < <(printf '%s\n' "${files[@]}" | grep '\.lua$' | grep -v '^\.config/matugen/templates/')
if [[ -n $luac ]]; then
    out=$(for f in "${luas[@]}"; do [[ -f $f ]] && "$luac" -p "$f" 2>&1; done)
    [[ -z $out ]] && ok "luac -p (${#luas[@]} ficheros)" || { bad "luac -p"; indent <<<"$out"; }
else
    skip "luac no está instalado (sudo pacman -S lua)"
fi

# 4. Python
mapfile -t pys < <(printf '%s\n' "${files[@]}" | grep '\.py$')
if ((${#pys[@]})); then
    out=$(for f in "${pys[@]}"; do
        [[ -f $f ]] && python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read(), sys.argv[1])' "$f" 2>&1
    done)
    [[ -z $out ]] && ok "python (${#pys[@]} ficheros)" || { bad "python"; indent <<<"$out"; }
fi

# 5. Rutas absolutas de un usuario concreto (el instalador lo pone todo bajo $HOME de quien lo use)
out=$(git grep -n -I -E '(^|[^[:alnum:]_./-])/home/[a-z_][a-z0-9_-]*/' -- . ':!.github/check.sh' 2>/dev/null |
    grep -vE '/home/(username|user|you|usuario)/')   # ejemplos en comentarios
[[ -z $out ]] && ok "sin rutas /home/<usuario>" || { bad "rutas /home/<usuario> (usa ~ o \$HOME)"; indent <<<"$out"; }

# 6. Ficheros locales o generados que no deberían estar en el repo
if [[ -f .github/exclude ]]; then
    out=$(git ls-files -ci --exclude-from=.github/exclude)
    [[ -z $out ]] && ok "sin ficheros locales ni generados" || { bad "ficheros que deberían estar fuera (.github/exclude)"; indent <<<"$out"; }
fi

# 7. Hyprland carga la config sin errores (solo dentro de una sesión de Hyprland)
if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && command -v hyprctl >/dev/null; then
    out=$(hyprctl configerrors 2>&1 | grep -v '^\s*$')
    [[ -z $out ]] && ok "hyprctl configerrors" || { bad "hyprctl configerrors"; indent <<<"$out"; }
else
    skip "Hyprland no está en marcha: no compruebo la config en vivo"
fi

echo
if ((fails)); then
    printf '\e[31m%d comprobación(es) fallida(s)\e[0m\n' "$fails"
    exit 1
fi
printf '\e[32mTodo bien\e[0m\n'
