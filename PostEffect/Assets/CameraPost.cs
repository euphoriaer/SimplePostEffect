using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Rendering;

public class CameraPost:MonoBehaviour
{

    public Material material;

    private void Start()
    {
        var m = material;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material!=null)
        {
            CommandBuffer cmd = CommandBufferPool.Get();
            cmd.Blit(source, destination,material);
        }
    }

}

