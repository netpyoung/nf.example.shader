Shader "example/GenericFakeBRDF "
{
    Properties
    {
        _BRDFTex("_BRDFTex", 2D) = "white" {}
        _OffsetU("_OffsetU", Range(0, 1)) = 0
        _OffsetV("_OffsetV", Range(0, 1)) = 0
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

            TEXTURE2D(_BRDFTex);            SAMPLER(sampler_BRDFTex);

            float _OffsetU;
            float _OffsetV;

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 uv           : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 L            : TEXCOORD1;
                float3 V            : TEXCOORD2;
                float3 N            : TEXCOORD3;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);
                
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                
                Light light = GetMainLight();
                OUT.L = normalize(light.direction);
                OUT.V = GetWorldSpaceViewDir(TransformObjectToWorld(IN.positionOS.xyz));
                OUT.N = TransformObjectToWorldNormal(IN.normalOS);

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 N = normalize(IN.N);
                half3 L = normalize(IN.L);
                half3 V = normalize(IN.V);

                half NdotV = dot(N, V);
                half NdotL = dot(N, L);

                half2 brdfUV;
                brdfUV.x = saturate(NdotV + _OffsetU);
                brdfUV.y = 1 - (saturate(NdotL * 0.5 + 0.5) + _OffsetV);
                half3 brdfTex = SAMPLE_TEXTURE2D(_BRDFTex, sampler_BRDFTex, brdfUV).rgb;
                return half4(brdfTex, 1);
            }
            ENDHLSL
        }
    }
}
