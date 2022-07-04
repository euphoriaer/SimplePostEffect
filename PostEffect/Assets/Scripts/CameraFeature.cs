using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CameraFeature : ScriptableRendererFeature
{
    public Material Material; //UniversalRenderPipelineAsset_Renderer 面板，设置材质
    private MyVolumeFeaturePass myPass;
    public string CameraName = "";
    public RenderPassEvent RenderPassEvent = RenderPassEvent.AfterRenderingTransparents;
    public override void Create()
    {
        myPass = new MyVolumeFeaturePass();
        myPass.renderPassEvent = RenderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(myPass);
        myPass.SetValue(renderer.cameraColorTarget, Material, CameraName); //传递摄像机图像，和材质，给Pass 处理
    }

    public class MyVolumeFeaturePass : ScriptableRenderPass
    {
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        private Material material;//接受从Feature 面板设置的材质
        private RenderTargetIdentifier source;//接受相机图像
        private string cameraName;

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            //判断是否场景相机,
            if ((renderingData.cameraData.cameraType != CameraType.SceneView))
            {
                //判断是否是指定相机,//判断是否开启后处理
                if ((renderingData.cameraData.camera.name != cameraName) &&
                    (renderingData.cameraData.postProcessEnabled == false))
                {
                    return;
                }
            }
            //执行后处理
            if (material == null)
            {
                return;
            }
            CommandBuffer cmd = CommandBufferPool.Get();
            //source  //源图像
            var dec = renderingData.cameraData.cameraTargetDescriptor; //目标图像
            RenderTargetHandle tempTargetHandle = new RenderTargetHandle();
            cmd.GetTemporaryRT(tempTargetHandle.id, dec);

            cmd.Blit(source, tempTargetHandle.Identifier(), material);
            //核心命令CommandBuffer
            cmd.Blit(tempTargetHandle.Identifier(), source); //相当于 Graphics.Blit

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public void SetValue(RenderTargetIdentifier source, Material material, string cameraName)
        {
            this.material = material; //接受面板材质
            this.source = source;
            this.cameraName = cameraName;
        }
    }
}