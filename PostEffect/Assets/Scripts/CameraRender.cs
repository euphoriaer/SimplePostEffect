using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace Assets.CustomRP
{
    public class CameraRender
    {
        const string bufferName = "Render Camera";
        static ShaderTagId shaderTagId = new ShaderTagId("SRPDefaultUnlit");

        CommandBuffer buffer = new CommandBuffer()
        {
            name = bufferName
        };

        private Camera camera;
        private ScriptableRenderContext context;
        CullingResults cullingResults;

        public void Render(ScriptableRenderContext context, Camera camera)
        {
            this.context = context;
            this.camera = camera;

            if (!Cull())
            {
                return;
            }
            Setup();
            DrawVisibleGeometry();
            Submit();
        }

        // 剪裁相机之外的物体
        private bool Cull()
        {
            ScriptableCullingParameters p;
            if (camera.TryGetCullingParameters(out p))
            {
                cullingResults = context.Cull(ref p);
                return true;
            }
            return false;
        }
        /// <summary>
        /// 绘制几何体
        /// </summary>
        private void DrawVisibleGeometry()
        {
            //设置绘制顺序，指定渲染相机 
            var sortingSettings = new SortingSettings(camera)
            {
                criteria = SortingCriteria.CommonOpaque
            };
            //设置渲染Shader Pass 和排序模式
            var drawingSettings = new DrawingSettings(shaderTagId, sortingSettings);
            //设置那类型可以被绘制
            var filteringSettings = new FilteringSettings(RenderQueueRange.all);

            //1.绘制不透明物体
            context.DrawRenderers(cullingResults,ref drawingSettings, ref filteringSettings);

            //2.天空盒
            context.DrawSkybox(camera);

            sortingSettings.criteria = SortingCriteria.CommonTransparent;
            //3.透明物体
            context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
            //
        }

        void ExecuteBuffer()
        {
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }
        //设置相机属性
        private void Setup()
        {
            context.SetupCameraProperties(camera);
            buffer.ClearRenderTarget(true,true,Color.clear);
            buffer.BeginSample(bufferName);
            ExecuteBuffer();

        }
        void Submit()
        {
            context.Submit();
        }
    }
}