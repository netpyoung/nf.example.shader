Shader "example/05_texture_camera"
{
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct APPtoVS
            {
                float4 positionOS : POSITION;
            };

            struct VStoFS
            {
                float4 positionCS       : SV_POSITION;
                float3 positionVS       : TEXCOORD0;
                float4 positionNDC      : TEXCOORD1;
                float3 toViewVectorWS   : TEXCOORD2;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                
                OUT.positionCS = vertexInputs.positionCS;
                OUT.positionVS = vertexInputs.positionVS;
                OUT.positionNDC = vertexInputs.positionNDC;
                
                OUT.toViewVectorWS = _WorldSpaceCameraPos - vertexInputs.positionWS;

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                float2 screenUV = (IN.positionNDC.xy / IN.positionNDC.w);

                float sceneRawDepth = SampleSceneDepth(screenUV);
                float sceneEyeDepth = LinearEyeDepth(sceneRawDepth, _ZBufferParams);

                float fragmentEyeDepth = -IN.positionVS.z;
                float3 scenePositionWS = (-IN.toViewVectorWS / fragmentEyeDepth) * sceneEyeDepth + _WorldSpaceCameraPos;
                float4 color = float4(frac(scenePositionWS), 1.0);
                return color;
            }
            ENDHLSL
        }
    }
}
