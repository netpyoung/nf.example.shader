Shader "BillboardFixYAxis"
{
    Properties
    {
        _MainTex("texture", 2D) = "white" {}
        [Toggle(IS_BILLBOARD)]_IsBillboard("Apply Billboard?", Float) = 1
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
            Name "BILLBOARD_FIX_Y_AXIS"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _ IS_BILLBOARD

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
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
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                #if IS_BILLBOARD
                    float2 viewDirWS = -normalize(
                    GetCameraPositionWS().xz - UNITY_MATRIX_M._m03_m23
                    );

                    float2x2 ROTATE_Y_AXIS_M = {
                        viewDirWS.y, viewDirWS.x,
                        -viewDirWS.x, viewDirWS.y
                    };

                    float3 positionOS;
                    positionOS.xz = mul(ROTATE_Y_AXIS_M, IN.positionOS.xz);
                    positionOS.y = IN.positionOS.y;

                    OUT.positionCS = TransformObjectToHClip(positionOS);
                #else
                    OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                #endif

                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
            }
            ENDHLSL
        }
    }
}
