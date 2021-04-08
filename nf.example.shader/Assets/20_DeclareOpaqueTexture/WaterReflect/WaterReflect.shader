Shader "WaterReflect"
{
    // Queue / RenderType 확인.
    // PipelineAsset> General> Opaque Texture> 체크.

    Properties
    {
        _Height("Height", Float) = 1
    }

    SubShader
    {
       Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Transparent" // ***
            "RenderType" = "Transparent"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite Off

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl" // SampleSceneColor

            CBUFFER_START(UnityPerMaterial)
                half _Height;
            CBUFFER_END


            struct APPtoVS
            {
                float4 positionOS   : POSITION;
            };

            struct VStoFS
            {
                float4 positionCS      : SV_POSITION;
                float4 positionNDC      : TEXCOORD3;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = vertexInputs.positionCS;
                OUT.positionNDC = vertexInputs.positionNDC;
                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half2 screenUV = IN.positionNDC.xy / IN.positionNDC.w;
                half2 uv = half2(screenUV.x, 1 - screenUV.y + _Height);
                half3 mainColor = SampleSceneColor(uv);
                return half4(mainColor, 1);
            }
            ENDHLSL
        }
    }
}
