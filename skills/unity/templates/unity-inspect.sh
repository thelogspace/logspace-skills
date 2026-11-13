#!/usr/bin/env bash
# Token-cheap view of Unity serialized YAML.
#   unity-inspect.sh <file.unity|file.prefab>   → GameObject hierarchy with components and script names
#   unity-inspect.sh --usages <Script.cs|X.prefab> → scenes/prefabs/assets that reference it (by GUID)
set -euo pipefail
cd "$(dirname "$0")/.."

guid_of() { sed -n 's/^guid: //p' "$1.meta" 2>/dev/null; }
name_of_guid() {
  local m; m=$(grep -rl --include='*.meta' "guid: $1" Assets 2>/dev/null | head -n1 || true)
  if [[ -n "$m" ]]; then basename "${m%.meta}"; else echo "?${1:0:8}"; fi
}

if [[ "${1:-}" == "--usages" ]]; then
  target="${2:?file required}"; g=$(guid_of "$target")
  [[ -z "$g" ]] && { echo "No .meta / GUID for $target"; exit 1; }
  echo "References to $(basename "$target") (guid $g):"
  grep -rl --include='*.unity' --include='*.prefab' --include='*.asset' --include='*.controller' "$g" Assets 2>/dev/null \
    | sed 's/^/- /' || echo "- none"
  exit 0
fi

file="${1:?usage: unity-inspect.sh <file.unity|file.prefab> | --usages <file>}"

# Resolve every referenced GUID (scripts, nested prefabs) to a file name once.
map=$(mktemp); trap 'rm -f "$map"' EXIT
for g in $(grep -oE 'guid: [0-9a-f]{32}' "$file" | cut -d' ' -f2 | sort -u); do
  echo "$g $(name_of_guid "$g")" >> "$map"
done

awk -v mapfile="$map" -v title="$(basename "$file")" '
  BEGIN { while ((getline l < mapfile) > 0) { split(l, a, " "); gname[a[1]] = a[2] } }
  /^--- !u!/ {
    split($2, c, "!"); cls = c[3]; id = substr($3, 2); stripped = ($4 == "stripped")
    type = ""; next
  }
  type == "" && /^[A-Za-z][A-Za-z0-9]*:$/ { type = substr($0, 1, length($0) - 1); kind[id] = type; next }
  stripped { next }
  type == "GameObject" && /^  m_Name: / { name[id] = substr($0, 11); gos[++ngo] = id }
  type == "GameObject" && /^  m_IsActive: 0/ { inactive[id] = 1 }
  /^  m_GameObject: \{fileID: / { match($0, /fileID: -?[0-9]+/); go = substr($0, RSTART + 8, RLENGTH - 8); owner[id] = go
    if (type == "Transform" || type == "RectTransform") tr[go] = id
    else if (type != "MonoBehaviour") comps[go] = comps[go] (comps[go] ? ", " : "") type
  }
  type == "MonoBehaviour" && /^  m_Script: / { match($0, /guid: [0-9a-f]+/); g = substr($0, RSTART + 6, RLENGTH - 6)
    s = (g in gname) ? gname[g] : "?script"; sub(/\.cs$/, "", s)
    comps[owner[id]] = comps[owner[id]] (comps[owner[id]] ? ", " : "") s
  }
  (type == "Transform" || type == "RectTransform") && /^  m_Father: \{fileID: / {
    match($0, /fileID: -?[0-9]+/); father[id] = substr($0, RSTART + 8, RLENGTH - 8)
  }
  type == "PrefabInstance" && /^  m_SourcePrefab: / { match($0, /guid: [0-9a-f]+/); g = substr($0, RSTART + 6, RLENGTH - 6)
    prefabs[++np] = (g in gname) ? gname[g] : "?prefab"
  }
  function show(go, depth,   i, t, ch, pad) {
    pad = ""; for (i = 0; i < depth; i++) pad = pad "  "
    printf "%s- %s%s%s\n", pad, name[go], (inactive[go] ? " (inactive)" : ""), (comps[go] ? " [" comps[go] "]" : "")
    t = tr[go]
    for (i = 1; i <= ngo; i++) { ch = gos[i]; if (father[tr[ch]] == t && t != "") show(ch, depth + 1) }
  }
  END {
    printf "%s: %d GameObjects", title, ngo; if (np) printf ", %d prefab instances", np; print ""
    for (i = 1; i <= ngo; i++) { go = gos[i]; f = father[tr[go]]; if (f == "" || f == "0" || !(f in owner)) show(go, 0) }
    for (i = 1; i <= np; i++) print "- [prefab] " prefabs[i]
  }
' "$file"
