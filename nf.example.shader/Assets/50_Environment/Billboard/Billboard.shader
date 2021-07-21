Shader "Billboard"
{
    Properties
    {
        _MainTex("texture", 2D) = "white" {}
        _Scale("_Scale(x, y)", Vector) = (1, 1, 0, 0)
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
            Name "BILLBOARD"

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

            TEXTURE2D(_MainTex);		SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half2 _Scale;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS	: POSITION;
                float2 uv			: TEXCOORD0;

            };

            struct VStoFS
            {
                float4 positionCS	: SV_POSITION;
                float2 uv			: TEXCOORD0;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                #if IS_BILLBOARD
                    // _m00, _m01, _m02, _m03
                    // _m10, _m11, _m12, _m13
                    // _m20, _m21, _m22, _m23
                    // _m30, _m31, _m32, _m33
                    float3 positionVS = TransformWorldToView(UNITY_MATRIX_M._m03_m13_m23) + float3(IN.positionOS.xy * _Scale, 0);
                    OUT.positionCS = TransformWViewToHClip(positionVS);
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
