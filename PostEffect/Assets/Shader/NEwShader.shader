Shader "URP/MultiLightShadow"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
    
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        float4 _Diffuse;
        CBUFFER_END
        ENDHLSL
        
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            
            // 设置关键字
            #pragma shader_feature _AdditionalLights
            
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
                float3 normalOS: NORMAL;
                float4 tangentOS: TANGENT;
            };
            
            struct Varyings
            {
                
                float3 positionWS: TEXCOORD0;
                
            };


            Varyings vert(Attributes v)
            {
                Varyings o;
                // 获取不同空间下坐标信息
                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionWS = positionInputs.positionWS;
                
                // 获取世界空间下法线相关向量
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);

                return o;
            }
            
            /// lightColor：光源颜色
            /// lightDirectionWS：世界空间下光线方向
            /// lightAttenuation：光照衰减
            /// normalWS：世界空间下法线
            /// viewDirectionWS：世界空间下视角方向
            half3 LightingBased(half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS)
            {
                // 兰伯特漫反射计算
                //half NdotL = saturate(dot(normalWS, lightDirectionWS));
                half3 radiance = lightColor * lightAttenuation  * _Diffuse.rgb;
                // BlinnPhong高光反射
                //half3 halfDir = normalize(lightDirectionWS + viewDirectionWS);
                //half3 specular = lightColor * pow(saturate(dot(normalWS, halfDir)), _Gloss) * _Specular.rgb;
                
                return radiance;//+ specular;
            }
            
            half3 LightingBased(Light light, half3 normalWS, half3 viewDirectionWS)
            {
                // 注意light.distanceAttenuation * light.shadowAttenuation，这里已经将距离衰减与阴影衰减进行了计算
                return light.distanceAttenuation * light.shadowAttenuation * _Diffuse.rgb;
                
                return LightingBased(light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS);
            }
            
            half4 frag(Varyings i): SV_Target
            {
              
                  // 获取阴影坐标
                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS.xyz);
    
                // 使用HLSL的函数获取主光源数据
                Light mainLight = GetMainLight(shadowCoord);
                //half3 diffuse = LightingBased(mainLight, normalWS, viewDirWS);
                half3 diffuse = mainLight.distanceAttenuation * mainLight.shadowAttenuation * _Diffuse.rgb;

                //half3 ambient = SampleSH(normalWS);
                return half4(diffuse, 1.0);
            }
            
            ENDHLSL
            
        }
        
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}
