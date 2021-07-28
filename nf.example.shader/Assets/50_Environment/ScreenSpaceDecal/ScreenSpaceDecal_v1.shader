Shader "ScreenSpaceDecal_v1"
{
    // ref:
    // - [SIGGRAPH2012 : Screen space decals in Warhammer 40,000: Space Marine](https://dl.acm.org/doi/10.1145/2343045.2343053)
    // - [스크린 스페이스 데칼에 대해 자세히 알아보자(워햄머 40,000: 스페이스 마린)](https://www.slideshare.net/blindrendererkr/40000)

    Properties
    {
        _MainTex("texture", 2D) = "white" {}
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
            Name "SCREEN_SPACE_DECAL_V1"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Cull Back
            ZWrite Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float4 positionNDC : TEXCOORD0;
            };
            
            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(IN.positionOS.xyz);

                OUT.positionCS = vertexPositionInput.positionCS;
                // positionNDC: [0, w]
                OUT.positionNDC = vertexPositionInput.positionNDC;

                return OUT;
            }
            
            half4 frag(VStoFS IN) : SV_Target
            {
                // ============== 1. 씬뎁스 구하기
                // uv_Screen: [0, 1]
                half2 uv_Screen = IN.positionNDC.xy / IN.positionNDC.w;
                half sceneRawDepth = SampleSceneDepth(uv_Screen);
                half sceneEyeDepth = LinearEyeDepth(sceneRawDepth, _ZBufferParams);

                // ============== 2. 뎁스로부터 3D위치를 구하기
                // ndc: [-1, 1]
                half2 ndc = uv_Screen * 2.0 - 1.0;
                half4 positionVS_decal;
                positionVS_decal.x = (ndc.x * sceneEyeDepth) / unity_CameraProjection._11;
                positionVS_decal.y = (ndc.y * sceneEyeDepth) / unity_CameraProjection._22;
                positionVS_decal.z = -sceneEyeDepth;
                positionVS_decal.w = 1;

                half4x4 I_MV = mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V);
                // positionOS_decal: [-0.5, 0.5] // clip 으로 잘려질것이기에
                half4 positionOS_decal = mul(I_MV, positionVS_decal);

                // ============== 3. SSD상자 밖이면 그리지않기
                clip(0.5 - abs(positionOS_decal.xyz));

                // ============== 4. 데칼 그리기
                // uv_decal: [0, 1]
                half2 uv_decal = positionOS_decal.xz + 0.5;
                half2 uv_MainTex = TRANSFORM_TEX(uv_decal, _MainTex);
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv_MainTex);
                return mainTex;
            }
            ENDHLSL
        }
    }
}
