#!/usr/bin/env bash
# Compila los APK de release para publicar. Se niega a compilar si falta la
# configuración: sin URL la app no tendría tasas, y sin la llave de release la
# actualización no se instalaría encima de la versión de los usuarios.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f config/prod.json ]]; then
  echo "Falta config/prod.json (copia config/example.json y completa la URL)." >&2
  exit 1
fi
if grep -q "example.com" config/prod.json; then
  echo "config/prod.json todavía tiene la URL de ejemplo." >&2
  exit 1
fi
if [[ ! -f android/key.properties ]]; then
  echo "Falta android/key.properties (llave de release, ver docs/publicar.md > Firma)." >&2
  exit 1
fi

flutter build apk --release --split-per-abi --dart-define-from-file=config/prod.json
