using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class MyVolumeFeature : ScriptableRendererFeature
{
    public Material Material; //UniversalRenderPipelineAsset_Renderer 面板，设置材质
    private MyVolumeFeaturePass myPass;

    public override void Create()
    {
        myPass = new MyVolumeFeaturePass();
        myPass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
    }


    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(myPass);
        myPass.SetValue(renderer.cameraColorTarget, Material); //传递摄像机图像，和材质，给Pass 处理
    }
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

    private Material Material;//接受从Feature 面板设置的材质
    private RenderTargetIdentifier source;//接受相机图像

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.camera.name != "UIMain Camera (4)")
        {
            return;
        }
        //执行后处理
        if (Material == null)
        {
            return;
        }
        CommandBuffer cmd = CommandBufferPool.Get();
        //source  //源图像
        var dec = renderingData.cameraData.cameraTargetDescriptor; //目标图像
        RenderTargetHandle tempTargetHandle = new RenderTargetHandle();
        cmd.GetTemporaryRT(tempTargetHandle.id, dec);

        cmd.Blit(source, tempTargetHandle.Identifier(), Material);
        //核心命令CommandBuffer
        cmd.Blit(tempTargetHandle.Identifier(), source); //相当于 Graphics.Blit

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    public void SetValue(RenderTargetIdentifier source, Material material)
    {
        Material = material; //接受面板材质
        this.source = source;
    }
}