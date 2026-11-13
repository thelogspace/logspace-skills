---
name: unity
description: Unity stack of LogSpace (Unity 6 LTS, URP mobile, standalone mobile games). Creates the project in batchmode, installs packages, applies Player Settings (package ID, IL2CPP, ARM64, target SDK, Linear, new Input System), sets up the folder/asmdef structure, Git LFS, formatter + Roslyn analyzers, EditMode/PlayMode tests and GameCI. Also the rulebook for every Unity coding task. Use for "unity", "unity oyun", "mobil oyun", "sahne", "prefab", "C# script", and from the init flow for unity-game.
---

# LogSpace Unity

Before writing code: `references/best-practices.md` and `references/pitfalls.md`. Read them at the start of every Unity task.

## 0. Requirements

- Unity Hub + **the latest Unity 6 LTS** with the Android Build Support (OpenJDK, SDK & NDK) and iOS Build Support modules. Use the version shown as LTS in Hub; if it isn't installed, ask the user to install it.
- `git lfs`, `dotnet` SDK (for the formatter and lint).
- Editor path: `UNITY=/Applications/Unity/Hub/Editor/<version>/Unity.app/Contents/MacOS/Unity`

## 1. Create (URP template)

```bash
TEMPLATE=$(ls "$(dirname "$UNITY")"/../../../Data/Resources/PackageManager/ProjectTemplates/com.unity.template.universal-3d*.tgz 2>/dev/null | head -n1)
# for 2D: com.unity.template.universal-2d*
"$UNITY" -batchmode -quit -createProject "$PWD" -cloneFromTemplate "$TEMPLATE" -logFile -
```

If the template isn't found or creation fails: ask the user to create a "Universal 3D" (or "Universal 2D") project in this folder from Unity Hub, then continue from step 2.

## 2. Git LFS + attributes (before the first commit)

```bash
cp templates/gitattributes .gitattributes
git lfs install --local
```

`.gitignore`: `gh api gitignore/templates/Unity` (logspace:versioning). Project Settings → Editor: **Asset Serialization = Force Text**, **Version Control = Visible Meta Files** (the defaults; check them). For merging scenes and prefabs, UnityYAMLMerge is defined in `.gitattributes`; each developer adds the merge tool to their git config once (`scripts/setup-stack.sh`).

## 3. Packages and settings

Copy `templates/ProjectSetup.cs` and `templates/BuildScript.cs` to `Assets/_Project/Scripts/Editor/`, and `templates/Game.Editor.asmdef` to the same folder.

```bash
# packages (Input System, Addressables, Localization, Test Framework, Code Coverage)
"$UNITY" -batchmode -projectPath . -executeMethod LogSpace.Editor.ProjectSetup.InstallPackages -logFile -
# Player Settings, folders; the target SDK value comes from logspace:store-compliance
LOGSPACE_ANDROID_TARGET_SDK=<api> "$UNITY" -batchmode -quit -projectPath . \
  -executeMethod LogSpace.Editor.ProjectSetup.Configure -logFile -
```

What `Configure` applies: company name `LogSpace`, product name, package ID (Android + iOS), IL2CPP, ARM64, App Bundle, target SDK, Linear color space, incremental GC, only the new Input System, version from `version.txt`, folder structure.

## 4. Structure

```
Assets/
  _Project/
    Art/  Audio/  Prefabs/  Scenes/  ScriptableObjects/  Settings/  Localization/
    Scripts/
      Runtime/   Game.Runtime.asmdef    # game code
      Logic/     Game.Logic.asmdef      # PURE C# rules (no UnityEngine reference) → fast EditMode tests
      Editor/    Game.Editor.asmdef
  Tests/
    EditMode/   Tests.EditMode.asmdef   # Logic + Runtime unit tests
    PlayMode/   Tests.PlayMode.asmdef   # scene/integration tests
  Analyzers/    # Microsoft.Unity.Analyzers DLL (label: RoslynAnalyzer)
# csc.rsp (-warnaserror+) next to each Game.* and Tests.* asmdef → only our code fails on warnings, not ThirdParty
version.txt     # single version source (release-please "simple")
```

The `_Project` prefix keeps our files apart from third-party assets. Third-party assets live in `Assets/ThirdParty/`; they're excluded from formatting and the guard.

## 5. Lint and format

- **Format**: CSharpier (`dotnet new tool-manifest && dotnet tool install csharpier`); `scripts/format.sh` formats only `Assets/_Project` and `Assets/Tests`.
- **Analyzers**: take the latest `Microsoft.Unity.Analyzers` DLL from NuGet, put it in `Assets/Analyzers/`, and give it the **RoslynAnalyzer** label in the Inspector. With a `csc.rsp` file (`-warnaserror+`) next to each of our asmdefs, every warning in our assemblies fails the compile; third-party code isn't affected.
- `scripts/lint.sh`: if the Unity-generated `.sln` exists, `dotnet build -warnaserror` (fast); if not, it gives a warning; CI catches it in any case via the compile.

## 6. Tests

- `scripts/test.sh`: EditMode + PlayMode in batchmode, with Code Coverage. If the project is open in the editor (lock file), batchmode can't run; then it says so and passes — run the tests from the Test Runner window; CI runs them in any case.
- CI: `templates/ci.yml` (GameCI `unity-test-runner`). Required secrets: `UNITY_LICENSE`, `UNITY_EMAIL`, `UNITY_PASSWORD` (see the GameCI activation guide).
- Skeleton tests: Logic rules (EditMode), `ProjectSetup` values (package ID, IL2CPP, ARM64 — EditMode), the boot scene opens without errors (PlayMode), localization tables complete.

## 7. Token economy (Unity burns the most tokens)

- `templates/unity-inspect.sh` → `scripts/unity-inspect.sh`. `scripts/unity-inspect.sh Assets/_Project/Scenes/Level01.unity` prints the GameObject hierarchy with components and script names (a scene that costs tens of thousands of tokens becomes a short tree); `--usages Assets/_Project/Scripts/Runtime/Player.cs` lists the scenes/prefabs that use it.
- The plugin's read guard blocks unbounded reads of serialized YAML; `.ignore` keeps `.meta` and YAML out of searches (`logspace:token-economy`).
- Change scenes and prefabs through editor scripts / unity-mcp, not by editing YAML by hand (it's also error-prone: fileIDs and GUIDs).
- `scripts/test.sh` writes the full Unity logs to files and prints only the result summary and failed test names.

## 8. Build

`BuildScript.BuildAndroid` / `BuildiOS`: version from `version.txt`, build number from `BUILD_NUMBER` (CI `github.run_number`). Android signing: keystore from CI secrets (GameCI `androidKeystoreBase64`, `androidKeystorePass`, `androidKeyaliasName`, `androidKeyaliasPass`).
