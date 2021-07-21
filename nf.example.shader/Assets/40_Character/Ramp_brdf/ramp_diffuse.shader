Shader "ramp_diffuse"
{
    Properties
    {
        _MainTex("texture", 2D) = "white" {}
        _DiffuseTex("_DiffuseTex", 2D) = "white" {}
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
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);
            TEXTURE2D(_DiffuseTex);	SAMPLER(sampler_DiffuseTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS	: POSITION;
                float2 uv			: TEXCOORD0;
                float4 normalOS		: NORMAL;
            };

            struct VStoFS
            {
                float4 positionCS	: SV_POSITION;
                float2 uv			: TEXCOORD0;
                float3 N			: TEXCOORD1;
                float3 V			: TEXCOORD2;
            };
            
            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.N = TransformObjectToWorldDir(IN.normalOS.xyz);

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                Light light = GetMainLight();
                half3 L = normalize(light.direction);
                half3 N = normalize(IN.N);

                half u = dot(L, N) * 0.5 + 0.5;

                half3 diffuseTex = SAMPLE_TEXTURE2D(_DiffuseTex, sampler_DiffuseTex, half2(u, 0)).rgb;

                return half4(diffuseTex * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb, 1);
            }
            ENDHLSL
        }
    }
}
