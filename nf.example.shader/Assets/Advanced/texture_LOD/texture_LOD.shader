Shader "example/texture_LOD"
{
    Properties
    {
        _MainTex("_MainTex", 2D) = "white" {}
        _ShaperTex("_ShaperTex", 2D) = "white" {}
        [IntRange] _LOD("_LOD", Range(0, 5)) = 0
        [Toggle(_IS_SHARPEN)]
        _IsSharpen("_IsSharpen", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma multi_compile_local _ _IS_SHARPEN
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_ShaperTex);      SAMPLER(sampler_ShaperTex);
        

            int _LOD;

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float2 uv            : TEXCOORD0;

            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float2 uv            : TEXCOORD0;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
#if _IS_SHARPEN
                return SAMPLE_TEXTURE2D_LOD(_ShaperTex, sampler_ShaperTex, IN.uv, _LOD);
#else
                return SAMPLE_TEXTURE2D_LOD(_MainTex, sampler_MainTex, IN.uv, _LOD);
#endif
            }
            ENDHLSL
        }
    }
}
