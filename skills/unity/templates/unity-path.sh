#!/usr/bin/env bash
# Sets UNITY to the editor matching ProjectSettings/ProjectVersion.txt (override with UNITY_PATH).
version=$(sed -n 's/^m_EditorVersion: //p' ProjectSettings/ProjectVersion.txt 2>/dev/null)
UNITY="${UNITY_PATH:-/Applications/Unity/Hub/Editor/${version}/Unity.app/Contents/MacOS/Unity}"
export UNITY
