using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace Assets.CustomRP
{
    public class CameraRender
    {
        private ScriptableRenderContext context;
        private Camera camera;
        const string bufferName = "Render Camera";
        CommandBuffer buffer = new CommandBuffer()
        {
            name = bufferName
        };
        void ExecuteBuffer()
        {
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }
        public void Render(ScriptableRenderContext context, Camera camera)
        {
            this.context = context;
            this.camera = camera;

            Setup();
            DrawVisibleGeometry();
            Submit();
        }
        //设置相机属性
        private void Setup()
        {
            context.SetupCameraProperties(camera);
            buffer.ClearRenderTarget(true,true,Color.clear);
            buffer.BeginSample(bufferName);
            ExecuteBuffer();

        }

        private void DrawVisibleGeometry()
        {
            context.DrawSkybox(camera);
        }
        void Submit()
        {
            context.Submit();
        }
    }
}