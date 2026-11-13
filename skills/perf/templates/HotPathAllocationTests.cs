using NUnit.Framework;
using Is = UnityEngine.TestTools.Constraints.Is;

namespace LogSpace.Tests.EditMode
{
    /// <summary>
    /// Code that runs every frame must not allocate GC memory (GC spikes = stutter on mobile).
    /// Add one test per hot path. Example below; replace ScoreCalculator with your own type.
    /// </summary>
    public class HotPathAllocationTests
    {
        [Test]
        public void ScoreCalculator_Add_DoesNotAllocate()
        {
            var calculator = new ScoreCalculator();
            calculator.Add(1); // warm-up: first-call allocations (static init, JIT) don't count

            Assert.That(() => calculator.Add(10), Is.Not.AllocatingGCMemory());
        }
    }
}
