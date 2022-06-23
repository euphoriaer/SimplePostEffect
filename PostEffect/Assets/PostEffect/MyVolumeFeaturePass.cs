using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class MyVolumeFeature : ScriptableRendererFeature
{
    public Material Material; //UniversalRenderPipelineAsset_Renderer 面板，设置材质
    public Color BlendColor;
    private MyVolumeFeaturePass myPass;

    public override void Create()
    {
        myPass = new MyVolumeFeaturePass();
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(myPass);
        myPass.SetValue(renderer.cameraColorTarget, Material, BlendColor); //传递给Pass 处理
    }
}

public class MyVolumeFeaturePass : ScriptableRenderPass
{
    private Material Material;
    private RenderTargetIdentifier source;
    private Color color;//接受面板颜色
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        MyVolume Volume = VolumeManager.instance.stack.GetComponent<MyVolume>();

        if (!Volume.IsActive())//没激活Volume 则不后处理
        {
            return;
        }
        //执行后处理
        //设置要混合的材质参数，从Volume 获取
        Material = Volume.Material.value;
        Material.SetColor("_Color", Volume.BlendColor.value);

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

    public void SetValue(RenderTargetIdentifier source, Material material, Color blendColor)
    {
        Material = material; //接受面板材质
        this.source = source;
        color = blendColor;
    }
}