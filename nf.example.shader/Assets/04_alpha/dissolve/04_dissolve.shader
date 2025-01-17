﻿Shader "example/04_dissolve"
{
    Properties
    {
        _Texture("texture", 2D) = "white" {}
        _TexDissolve("dissolve", 2D) = "white" {}
        _Cutoff("Cutoff", Range(0, 1)) = 0.25
        _EdgeColor1("Edge colour 1", Color) = (1.0, 1.0, 1.0, 1.0)
        _EdgeColor2("Edge colour 2", Color) = (1.0, 1.0, 1.0, 1.0)
        _DissolveLevel("Dissolution level", Range(0, 1)) = 0.1
        _EdgeWidth("Edge width", Range(0, 1)) = 0.1
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
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


            TEXTURE2D(_Texture);        SAMPLER(sampler_Texture);
            TEXTURE2D(_TexDissolve);    SAMPLER(sampler_TexDissolve);

            CBUFFER_START(UnityPerMaterial)
            float4 _Texture_ST;
            float4 _TexDissolve_ST;

            half _Cutoff;
            half _DissolveLevel;
            half _EdgeWidth;
            half4 _EdgeColor1;
            half4 _EdgeColor2;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _Texture);

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half cutout = SAMPLE_TEXTURE2D(_TexDissolve, sampler_TexDissolve, IN.uv).r;
                clip(cutout - _Cutoff);

                half4 color = SAMPLE_TEXTURE2D(_Texture, sampler_Texture, IN.uv);
                if (cutout < color.a && cutout < _DissolveLevel + _EdgeWidth)
                {
                    color = lerp(_EdgeColor1, _EdgeColor2, (cutout - _DissolveLevel) / _EdgeWidth);
                }

                return color;
            }
            ENDHLSL
        }
    }
}
