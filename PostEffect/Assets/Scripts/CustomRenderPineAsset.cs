using UnityEngine;
using UnityEngine.Rendering;

namespace Assets.CustomRP
{
    [CreateAssetMenu(menuName = "Rendering/CtrateCustomRenderPipline")]
    public class CustomRenderPineAsset : RenderPipelineAsset
    {
        protected override RenderPipeline CreatePipeline()
        {
            return new CustomRenderPipeline();
        }
    }
}