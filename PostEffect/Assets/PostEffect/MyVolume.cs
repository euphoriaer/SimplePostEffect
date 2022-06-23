using System;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class MyVolume : VolumeComponent, IPostProcessComponent
{
    //需要封装参数
    public MaterialParameter Material = new MaterialParameter(null, false);
    //需要封装参数
    public ColorParameter BlendColor = new ColorParameter(Color.white);

    public bool IsActive()
    {
        if (Material.overrideState == false)//如果材质没有被勾选，则不激活
        {
            return false;
        }

        return true;
    }

    public bool IsTileCompatible()
    {
        return true;
    }
}


[Serializable]
public sealed class MaterialParameter : VolumeParameter<Material>
{
    //没有Material 封装，手动封装参数
    public MaterialParameter(Material value, bool overrideState = false)
        : base(value, overrideState)
    {
    }
}