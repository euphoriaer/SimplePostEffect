using UnityEngine;
using UnityEngine.Rendering;

namespace Assets.CustomRP
{
    public class CustomRenderPipeline : RenderPipeline
    {
        CameraRender renderer = new CameraRender();
        protected override void Render(ScriptableRenderContext context, Camera[] cameras)
        {
            foreach (var camera in cameras)
            {
                renderer.Render(context, camera);
            }
        }

    }


}