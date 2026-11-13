using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.PackageManager;
using UnityEditor.PackageManager.Requests;
using UnityEngine;

namespace LogSpace.Editor
{
    /// <summary>
    /// Batchmode project setup used by the logspace:unity skill.
    /// Values come from .logspace/project.json; the target SDK from LOGSPACE_ANDROID_TARGET_SDK.
    /// </summary>
    public static class ProjectSetup
    {
        public const string Company = "LogSpace";

        static readonly string[] Packages =
        {
            "com.unity.inputsystem",
            "com.unity.addressables",
            "com.unity.localization",
            "com.unity.test-framework",
            "com.unity.testtools.codecoverage",
        };

        static readonly string[] Folders =
        {
            "Assets/_Project/Art",
            "Assets/_Project/Audio",
            "Assets/_Project/Prefabs",
            "Assets/_Project/Scenes",
            "Assets/_Project/ScriptableObjects",
            "Assets/_Project/Settings",
            "Assets/_Project/Localization",
            "Assets/_Project/Scripts/Runtime",
            "Assets/_Project/Scripts/Logic",
            "Assets/_Project/Scripts/Editor",
            "Assets/Tests/EditMode",
            "Assets/Tests/PlayMode",
            "Assets/Analyzers",
            "Assets/ThirdParty",
        };

        static AddAndRemoveRequest _request;

        [Serializable]
        class ProjectInfo
        {
            public string displayName;
            public string packageId;
        }

        /// <summary>Installs the packages at the editor's recommended versions, then exits.</summary>
        public static void InstallPackages()
        {
            _request = Client.AddAndRemove(Packages);
            EditorApplication.update += WaitForPackages;
        }

        static void WaitForPackages()
        {
            if (!_request.IsCompleted)
            {
                return;
            }

            EditorApplication.update -= WaitForPackages;
            if (_request.Status == StatusCode.Success)
            {
                Debug.Log("[LogSpace] packages installed");
                EditorApplication.Exit(0);
            }
            else
            {
                Debug.LogError($"[LogSpace] package install failed: {_request.Error.message}");
                EditorApplication.Exit(1);
            }
        }

        /// <summary>Applies the LogSpace Player Settings and folder structure.</summary>
        public static void Configure()
        {
            var project = JsonUtility.FromJson<ProjectInfo>(File.ReadAllText(".logspace/project.json"));
            var targetSdkText =
                Environment.GetEnvironmentVariable("LOGSPACE_ANDROID_TARGET_SDK")
                ?? throw new InvalidOperationException(
                    "LOGSPACE_ANDROID_TARGET_SDK is missing (get it from logspace:store-compliance)"
                );

            PlayerSettings.companyName = Company;
            PlayerSettings.productName = project.displayName;
            PlayerSettings.bundleVersion = ReadVersion();

            foreach (var target in new[] { NamedBuildTarget.Android, NamedBuildTarget.iOS })
            {
                PlayerSettings.SetApplicationIdentifier(target, project.packageId);
                PlayerSettings.SetScriptingBackend(target, ScriptingImplementation.IL2CPP);
                PlayerSettings.SetManagedStrippingLevel(target, ManagedStrippingLevel.Low);
            }

            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
            PlayerSettings.Android.targetSdkVersion = (AndroidSdkVersions)int.Parse(targetSdkText);
            EditorUserBuildSettings.buildAppBundle = true;

            PlayerSettings.colorSpace = ColorSpace.Linear;
            PlayerSettings.gcIncremental = true;
            UseNewInputSystemOnly();

            foreach (var folder in Folders)
            {
                Directory.CreateDirectory(folder);
            }

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            Debug.Log($"[LogSpace] configured {project.packageId}, targetSdk {targetSdkText}");
        }

        public static string ReadVersion() =>
            File.Exists("version.txt") ? File.ReadAllText("version.txt").Trim() : "0.1.0";

        static void UseNewInputSystemOnly()
        {
            var settings = AssetDatabase
                .LoadAllAssetsAtPath("ProjectSettings/ProjectSettings.asset")
                .FirstOrDefault();
            if (settings == null)
            {
                return;
            }

            var serialized = new SerializedObject(settings);
            var handler = serialized.FindProperty("activeInputHandler");
            if (handler != null)
            {
                handler.intValue = 1; // 0 = old, 1 = new Input System, 2 = both
                serialized.ApplyModifiedPropertiesWithoutUndo();
            }
        }
    }
}
