Shader "URP/MultiLightShadow"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
      
        Pass
        {
            Tags
            {
                "RenderType" = "Opaque"
                "RenderPipeline" = "UniversalPipeline"
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        
            float4 _Diffuse;


            // 接收阴影所需关键字
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS: POSITION;
            };

            struct Varyings
            {
                float4 positionCS: POSITION;//或者 SV_POSITION
                float3 positionWS: TEXCOORD0;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                // 获取不同空间下坐标信息
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = positionInputs.positionCS;
                o.positionWS = positionInputs.positionWS;


                return o;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // 获取阴影坐标
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS.xyz);
                //使用HLSL的函数获取主光源数据
                Light mainLight = GetMainLight(shadowCoord);
                half3 diffuse = mainLight.color * mainLight.distanceAttenuation * mainLight.shadowAttenuation * _Diffuse
                    .rgb;
                return half4(diffuse, 1.0);
            }
            ENDHLSL
        }
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}