Shader "SpriteFlipBook"
{
    Properties
    {
        [NoScaleOffset] _MainTex("_MainTex", 2D)        = "white" {}

        _ColumnsX("Columns (X)", Int)                    = 8
        _RowsY("Rows (Y)", Int)                            = 8

        _FramesPerSeconds("_FramesPerSeconds", Float)    = 3
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Pass
        {
            Name "SPRITE_FLIP_BOOK"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            uint _ColumnsX;
            uint _RowsY;
            half _FramesPerSeconds;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float2 uv            : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float2 subUV        : TEXCOORD0;
            };

            half2 GetSubUV(in half2 uv, in half frame, in int2 imageCount)
            {
                half2 scale = 1.0 / imageCount;

                half index = floor(frame);
                half2 offset = half2(
                fmod(index, imageCount.x),
                -1 - floor(index * scale.x)
                );
                return (uv + offset) * scale;
            }

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);

                half frameNumber = _Time.y * _FramesPerSeconds;
                OUT.subUV = GetSubUV(IN.uv, frameNumber, uint2(_ColumnsX, _RowsY));

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.subUV);
            }
            ENDHLSL
        }
    }
}
