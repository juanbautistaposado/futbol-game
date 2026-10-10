#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_dir="$repo_dir/apps/free-kick-3d"
output_dir="$project_dir/build/web"
godot_bin="${GODOT_BIN:-godot}"

if ! command -v "$godot_bin" >/dev/null 2>&1; then
  echo "No se encontró Godot. Instalalo o definí GODOT_BIN con la ruta del ejecutable." >&2
  exit 1
fi

mkdir -p "$output_dir"
"$godot_bin" --headless --path "$project_dir" --editor --import --quit
"$godot_bin" --headless --path "$project_dir" --export-release Web "$output_dir/index.html"

for file in index.html index.js index.wasm index.pck; do
  if [[ ! -s "$output_dir/$file" ]]; then
    echo "Exportación incompleta: falta $file." >&2
    exit 1
  fi
done
cp "$project_dir/web/_headers" "$output_dir/_headers"
cp "$project_dir/ui/fonts/Archivo-Variable.ttf" "$output_dir/archivo.ttf"
cp "$project_dir/web/favicon.ico" "$output_dir/favicon.ico"
echo "Exportación web lista: $output_dir"
du -sh "$output_dir"
