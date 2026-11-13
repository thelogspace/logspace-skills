using System;
using System.Collections;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.TestTools;
using Object = UnityEngine.Object;

namespace LogSpace.Tests.PlayMode
{
    /// <summary>
    /// Loading and unloading a level several times must not leave textures, meshes or objects behind.
    /// The scenes must be in the Build Settings scene list.
    /// </summary>
    public class SceneLeakTests
    {
        const int Cycles = 3;
        const string Scene = "Level01"; // copy the test per heavy scene, or loop over a list

        [UnityTest]
        public IEnumerator Level_LoadUnloadCycles_ReleaseAllAssets()
        {
            const string scene = Scene;
            yield return Cleanup();
            var before = Snapshot.Take();

            for (var i = 0; i < Cycles; i++)
            {
                yield return SceneManager.LoadSceneAsync(scene, LoadSceneMode.Additive);
                yield return SceneManager.UnloadSceneAsync(scene);
            }

            yield return Cleanup();
            var after = Snapshot.Take();

            Assert.That(after.Textures, Is.LessThanOrEqualTo(before.Textures), "leaked textures");
            Assert.That(after.Meshes, Is.LessThanOrEqualTo(before.Meshes), "leaked meshes");
            Assert.That(after.GameObjects, Is.LessThanOrEqualTo(before.GameObjects), "leaked GameObjects");
        }

        static IEnumerator Cleanup()
        {
            yield return Resources.UnloadUnusedAssets();
            GC.Collect();
            yield return null;
        }

        readonly struct Snapshot
        {
            public readonly int Textures;
            public readonly int Meshes;
            public readonly int GameObjects;

            Snapshot(int textures, int meshes, int gameObjects)
            {
                Textures = textures;
                Meshes = meshes;
                GameObjects = gameObjects;
            }

            public static Snapshot Take() =>
                new(
                    Resources.FindObjectsOfTypeAll<Texture>().Length,
                    Resources.FindObjectsOfTypeAll<Mesh>().Length,
                    Object.FindObjectsByType<GameObject>(FindObjectsSortMode.None).Length
                );
        }
    }
}
