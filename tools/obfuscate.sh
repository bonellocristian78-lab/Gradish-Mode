#!/bin/sh
# Obfuscates scripts in place with Prometheus (https://github.com/wcrddn/Prometheus), with tools/prometheus.config.lua:
#
#     tools/obfuscate.sh /path/to/Prometheus GradishCore Noise90 ...
#
# The readable scripts are on the branch "sorgenti": take one from there (git checkout sorgenti -- Noise90), run
# this on it, commit. Prometheus needs LuaJIT or Lua 5.1.
set -e
prometheus=$(cd "$1" && pwd)
shift
config="$(cd "$(dirname "$0")" && pwd)/prometheus.config.lua"
lua=$(command -v luajit || command -v lua5.1 || command -v lua)
for file in "$@"; do
	path="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
	(cd "$prometheus" && "$lua" cli.lua --nocolors --config "$config" --out "$path.obfuscated" "$path")
	mv "$path.obfuscated" "$path"
done
