Shader "Custom/BaseOutLine"
{
    Properties
    {
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        _Color("Outline Color", Color) = (0, 237, 255, 0)
        _Outline("Outline width", Range(.0, 0.1)) = 0.013
        [Toggle(_DiSSOLVE)]_Dissolve("溶解", int) = 0
        _DissolveEdgeColor("溶解色", Color) = (1, 1, 1, 1)//溶解色
        _DissolveMap("DissolveMap", 2D) = "white" {}
        _DissolveClip("溶解值", Range(0,1)) = 0
        _ColorFactor("溶解色强度", Range(0,1)) = 0.825
        _SrcBlend("Src Blend", int) = 1
        _DstBlend("Dst Blend", int) = 0
        _ZWrite("Z Write", int) = 1
        _ZOffset("Z Offset", float) = 0
        _ColorMask("Color Mask", int) = 15
        [Toggle(_TURN_STONE)]_turn_stone("石化", int) = 0
        _GrayScale("石化强度", Float) = 1

        _LightDir2("_LightDir", Vector) = (0, 1, 1, 0.1)
        _ShadowColor2("_ShadowColor", Color) = (0, 0, 0, 1)
        _ShadowFalloff2("_ShadowFalloff", Float) = 0
    }

    SubShader
    {
        LOD 500

        Pass
        {
            Tags
            {
                "Queue" = "Opaque" "RenderType" = "Geometry" "RenderPipeline" = "UniversalPipeline" "ShaderModel" = "4.5"
            }
            Cull Back
            ZWrite[_ZWrite]
            Blend[_SrcBlend][_DstBlend]
            Offset[_ZOffset],[_ZOffset]
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #pragma shader_feature _TURN_STONE
            #pragma multi_compile _ _DiSSOLVE

            sampler2D _MainTex;

            uniform float4 _MainTex_ST;
            uniform float4 _Color;
            uniform int _SrcBlend;
            uniform int _DstBlend;
            uniform int _ZWrite;
            uniform float _ZOffset;
            uniform float _GrayScale;

            sampler2D _DissolveMap;
            half3 _DissolveEdgeColor;
            half _DissolveClip;
            half _ColorFactor;

            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 pos : POSITION;
                float3 normal : NORMAL;
                float4 color : COLOR;
                float2 tex : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.pos = TransformObjectToHClip(input.vertex);
                output.normal = TransformObjectToWorldNormal(normalize(input.normal));
                output.tex = input.texcoord;
                return output;
            }

            half4 frag(Varyings input) :COLOR
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half4 o = tex2D(_MainTex, input.tex);
                #if _TURN_STONE
                half stone = o.r * 0.3 + o.g * 0.52 + o.b * 0.18;
                o.r = o.g = o.b = stone * _GrayScale;
                #endif
                #if _DiSSOLVE
                            half4 cutoutSource = tex2D(_DissolveMap,  input.tex);
                            clip(cutoutSource.r - _DissolveClip * 1.001);
                            float percentage = _DissolveClip / cutoutSource.r;
                            half3 edgeColor = _DissolveEdgeColor.rgb;
                            cutoutSource.a = FastSign(percentage - _ColorFactor);
                            o.rgb = lerp(o.rgb, edgeColor, saturate(cutoutSource.a));
                #endif
                return o;
            }
            ENDHLSL
        }

        Pass
        {
            Tags
            {
                "RenderType" = "Opaque" "IgnoreProjector" = "True" "LightMode" = "UniversalForward"
            }
            Name "Unlit"
            Cull Front
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #pragma multi_compile _ _DiSSOLVE
            half _Outline;
            half3 _Color;
            TEXTURE2D(_DissolveMap);
            SAMPLER(sampler_DissolveMap);
            half4 _DissolveMap_ST;
            half _DissolveClip;
            half _ColorFactor;
            half _DissolveEdge;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 vertex : POSITION;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.uv = TRANSFORM_TEX(input.uv, _DissolveMap);
                output.vertex = TransformObjectToHClip(input.positionOS + input.normal * _Outline);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half2 uv = input.uv;
                #if _DiSSOLVE
                                    half4 cutoutSource = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, uv);
                                    clip(cutoutSource.r - _DissolveClip * 1.001);
                                    float percentage = _DissolveClip / cutoutSource.r;
                                    cutoutSource.a = FastSign(percentage - _ColorFactor);
                                    return half4(_Color, cutoutSource.a);
                #else
                return half4(_Color, 1);
                #endif
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }
            ZWrite On
            ColorMask 0
            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        //阴影pass
        Pass
        {
            Name "Shadow"

            Tags
            {
                "Queue" = "Transparent"
                "RenderType" = "Transparent"
                "RenderPipeline" = "UniversalPipeline"
                "LightMode" = "UniversalForwardOnly"
            }
            //用使用模板测试以保证alpha显示正确
            Stencil
            {
                Ref 0
                Comp equal
                Pass incrWrap
                Fail keep
                ZFail keep
            }

            //透明混合模式
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest Less
            //ZWrite Always
            //关闭深度写入
            ZWrite on

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
            };

            float4 _LightDir2;
            float4 _ShadowColor2;
            float _ShadowFalloff2;

            float3 ShadowProjectPos(float4 vertPos)
            {
                float3 shadowPos;

                //得到顶点的世界空间坐标
                float3 worldPos = mul(unity_ObjectToWorld, vertPos).xyz;

                //灯光方向
                float3 lightDir = normalize(_LightDir2.xyz);

                //阴影的世界空间坐标（低于地面的部分不做改变）
                shadowPos.y = min(worldPos.y, _LightDir2.w);
                shadowPos.xz = worldPos.xz - lightDir.xz * max(0, worldPos.y - _LightDir2.w) / lightDir.y;

                return shadowPos;
            }

            v2f vert(appdata v)
            {
                v2f o;

                //得到阴影的世界空间坐标
                float3 shadowPos = ShadowProjectPos(v.vertex);

                //转换到裁切空间
                o.vertex = UnityWorldToClipPos(shadowPos);

                //得到中心点世界坐标
                float3 center = float3(unity_ObjectToWorld[0].w, _LightDir2.w, unity_ObjectToWorld[2].w);
                //计算阴影衰减
                float falloff = 1 - saturate(distance(shadowPos, center) * _ShadowFalloff2);

                //阴影颜色
                o.color = _ShadowColor2;
                o.color.a *= falloff;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return i.color;
            }
            ENDHLSL
        }
    }
}