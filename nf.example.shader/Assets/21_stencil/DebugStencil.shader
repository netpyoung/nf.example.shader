Shader "Stencil"
{
    Properties
    {
        _BaseColor("_BaseColor", Color) = (1, 1, 1, 1)

        [IntRange]
        _StencilRef("Stencil ID [0-255]",      Range(0, 255)) = 0

        [IntRange]
        _StencilReadMask("ReadMask [0-255]",   Range(0, 255)) = 255

        [IntRange]
        _StencilWriteMask("WriteMask [0-255]", Range(0, 255)) = 255

        [Enum(UnityEngine.Rendering.CompareFunction)]
        _StencilComp("Stencil Comparison",     Float) = 8 // Always

        [Enum(UnityEngine.Rendering.StencilOp)]
        _StencilPass("Stencil Pass",           Float) = 0 // Keep

        [Enum(UnityEngine.Rendering.StencilOp)]
        _StencilFail("Stencil Fail",           Float) = 0 // Keep

        [Enum(UnityEngine.Rendering.StencilOp)]
        _StencilZFail("Stencil ZFail",         Float) = 0 // Keep
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Geometry+1"
            "RenderType" = "Opaque"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Stencil
            {
                Ref            [_StencilRef]
                ReadMask    [_StencilReadMask]
                WriteMask    [_StencilWriteMask]
                Comp        [_StencilComp]
                Pass        [_StencilPass]
                Fail        [_StencilFail]
                ZFail        [_StencilZFail]
            }

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                return _BaseColor;
            }
            ENDHLSL
        }
    }
}
