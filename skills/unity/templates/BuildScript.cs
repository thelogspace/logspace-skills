using System;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace LogSpace.Editor
{
    /// <summary>
    /// CI builds. Version from version.txt, build number from BUILD_NUMBER (github.run_number).
    /// Unity -batchmode -quit -projectPath . -executeMethod LogSpace.Editor.BuildScript.BuildAndroid
    /// </summary>
    public static class BuildScript
    {
        public static void BuildAndroid() => Build(BuildTarget.Android, "build/Android/app.aab");

        public static void BuildiOS() => Build(BuildTarget.iOS, "build/iOS");

        static void Build(BuildTarget target, string path)
        {
            var buildNumber = int.Parse(Environment.GetEnvironmentVariable("BUILD_NUMBER") ?? "1");
            PlayerSettings.bundleVersion = ProjectSetup.ReadVersion();
            PlayerSettings.Android.bundleVersionCode = buildNumber;
            PlayerSettings.iOS.buildNumber = buildNumber.ToString();

            var options = new BuildPlayerOptions
            {
                scenes = EditorBuildSettings.scenes.Where(s => s.enabled).Select(s => s.path).ToArray(),
                locationPathName = path,
                target = target,
                options = BuildOptions.None,
            };

            var report = BuildPipeline.BuildPlayer(options);
            if (report.summary.result != BuildResult.Succeeded)
            {
                Debug.LogError($"[LogSpace] build failed: {report.summary.result}");
                EditorApplication.Exit(1);
            }
        }
    }
}
