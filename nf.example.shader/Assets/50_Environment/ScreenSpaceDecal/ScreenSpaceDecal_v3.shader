Shader "ScreenSpaceDecal_v3"
{
    Properties
    {
        _MainTex("texture", 2D) = "white" {}
    }

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
            Name "SCREEN_SPACE_DECAL_V3"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Cull Back
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

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
                float4 positionCS           : SV_POSITION;
                float4 positionNDC          : TEXCOORD0;
                float3 positionOS_camera    : TEXCOORD2;
                float4 positionOSw_viewRay  : TEXCOORD1;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(IN.positionOS.xyz);

                OUT.positionCS = vertexPositionInput.positionCS;
                OUT.positionNDC = vertexPositionInput.positionNDC;

                // float4x4 I_MV = mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V);
                // OUT.positionOS_camera = mul(I_MV, float4(0, 0, 0, 1)).xyz;
                // OUT.positionOSw_viewRay.xyz = mul((float3x3)I_MV, -vertexPositionInput.positionVS);
                // OUT.positionOSw_viewRay.w = vertexPositionInput.positionVS.z;

                float3 positionOS_camera = mul(UNITY_MATRIX_I_M, float4(_WorldSpaceCameraPos, 1)).xyz;
                OUT.positionOS_camera = positionOS_camera;
                OUT.positionOSw_viewRay.xyz = (positionOS_camera - IN.positionOS.xyz);
                OUT.positionOSw_viewRay.w = vertexPositionInput.positionVS.z;
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
                // positionOS_decal: [-0.5, 0.5] // clip 으로 잘려질것이기에
                half3 positionOS_decal = IN.positionOS_camera + (IN.positionOSw_viewRay.xyz / IN.positionOSw_viewRay.w) * sceneEyeDepth;
                
                // ============== 3. SSD상자 밖이면 그리지않기
                clip(0.5 - abs(positionOS_decal.xyz));

                // ============== 4. 데칼 그리기
                // uv_decal: [0, 1]
                half2 uv_decal = positionOS_decal.xz + 0.5;
                half2 uv_MainTex = TRANSFORM_TEX(uv_decal, _MainTex); // for Texture Tiling
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv_MainTex);

                // ============== 4. 페이드아웃 적용
                // ref: [http://ttmayrin.tistory.com/37](https://web.archive.org/web/20170508024615/http://ttmayrin.tistory.com/37)
                // #define HALF_Y 0.25f
                // mainTex *= (1.f - max((positionOS_decal.y - HALF_Y) / HALF_Y, 0.f));
                mainTex *= (1.f - max(4 * positionOS_decal.y - 1, 0.f));
                return mainTex;
            }
            ENDHLSL
        }
    }
}
