Shader "example/CrossFadeLOD"
{
    Properties
    {
        _MainTex("texture", 2D) = "white" {}
        _DitherTex("_DitherTex", 2D) = "white" {}
        
    }

        SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "AlphaTest"
            "RenderType" = "TransparentCutout"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma target 3.5

            #pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);     SAMPLER(sampler_MainTex);
            TEXTURE2D(_DitherTex);   SAMPLER(sampler_DitherTex);
            SAMPLER(unity_DitherMask);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _DitherTex_TexelSize;
            float4 unity_DitherMask_TexelSize;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float2 uv            : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float2 uv            : TEXCOORD0;
                float4 positionNDC   : TEXCOORD3;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);

                OUT.positionCS = vertexInputs.positionCS;
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                OUT.positionNDC = vertexInputs.positionNDC;

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

#ifdef LOD_FADE_CROSSFADE
                half2 screenUV = IN.positionNDC.xy / IN.positionNDC.w;
                float fade = unity_LODFade.x;

                // ex-1
                // float dither = (IN.positionCS.y % 32) / 32;
                // clip(fade - dither);

                // ex-2
                // half ditherTex = SAMPLE_TEXTURE2D(_DitherTex, sampler_DitherTex, IN.uv).r;
                // clip(fade - ditherTex);

                // ex-3
                //float2 ditherUV = screenUV.xy * _ScreenParams.xy * _DitherTex_TexelSize.xy;
                //half ditherTex = SAMPLE_TEXTURE2D(_DitherTex, sampler_DitherTex, ditherUV).r;
                //clip(fade - CopySign(ditherTex, fade));

                // ex-4
                // float2 fadeMaskSeed = IN.positionCS.xy;
                // LODDitheringTransition(fadeMaskSeed, fade);

                // ex-5
                //float2 ditherUV = screenUV * _ScreenParams.xy;
                //float DITHER_THRESHOLDS[16] =
                //{
                //    1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
                //    13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
                //    4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
                //    16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
                //};
                //uint index = (uint(ditherUV.x) % 4) * 4 + uint(ditherUV.y) % 4;
                //clip(fade - CopySign(DITHER_THRESHOLDS[index], fade));

                // ex-6
                float2 ditherUV = screenUV.xy * _ScreenParams.xy / 4.0;
                float dither = tex2D(unity_DitherMask, ditherUV).a;
                clip(fade - CopySign(dither, fade));
 #endif
                return mainTex;
            }
            ENDHLSL
        }
    }
}
