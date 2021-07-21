Shader "snow_2"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _PaintTex("Paint Texture", 2D) = "white" {}

        _SnowHeight("Snow Height", Range(0, 1)) = 0.3
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

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_PaintTex);        SAMPLER(sampler_PaintTex);

            CBUFFER_START(UnityPerMeterial)
            half4 _MainTex_ST;

            half _SnowHeight;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float3 normalOS     : NORMAL;
                float2 uv            : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float2 uv            : TEXCOORD0;

                float3 N            : TEXCOORD1;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                
                half3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                half paintVal = SAMPLE_TEXTURE2D_LOD(_PaintTex, sampler_PaintTex, OUT.uv, 0).r;
                positionWS.y += _SnowHeight;
                positionWS.y -= _SnowHeight * paintVal;

                OUT.positionCS = TransformWorldToHClip(positionWS);
                OUT.N = TransformObjectToWorldNormal(IN.normalOS);

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                half3 paintTex = SAMPLE_TEXTURE2D(_PaintTex, sampler_PaintTex, IN.uv).rgb;

                Light light = GetMainLight();

                half3 N = normalize(IN.N);
                half3 L = normalize(light.direction);

                half NdotL = saturate(dot(N, L));

                half3 diffuse = (mainTex * (1 - paintTex / 2) ) * NdotL;

                return half4(diffuse, 1);
            }
            ENDHLSL
        }
    }
}
