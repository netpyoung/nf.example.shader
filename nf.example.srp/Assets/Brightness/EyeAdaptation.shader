Shader "Hidden/EyeAdaptation"
{

    HLSLINCLUDE
    ENDHLSL

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Key("_Key", Float) = 1

    
    }

    SubShader
    {
        Pass // 0
        {
            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_LumaAdaptTex);   SAMPLER(sampler_LumaAdaptTex);
            TEXTURE2D(_LumaCurrTex);    SAMPLER(sampler_LumaCurrTex);

            float _Key;

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            float CalcLuminance(float3 color)
            {
                return dot(color, float3(0.299f, 0.587f, 0.114f));
            }


            float3 Reinhard_extended(float3 v, float max_white)
            {
                float3 numerator = v * (1.0f + (v / (max_white * max_white)));
                return numerator / (1.0f + v);
            }


            static const float3x3 RGB2XYZ = {
                0.5141364, 0.3238786, 0.16036376,
                0.265068, 0.67023428, 0.06409157,
                0.0241188, 0.1228178, 0.84442666
            };

            static const float3x3 XYZ2RGB = {
                2.5651,-1.1665,-0.3986,
                -1.0217, 1.9777, 0.0439,
                0.0753, -0.2543, 1.1892
            };

            half AutoKey(half avgLum)
            {
                return saturate(1.5 - 1.5 / (avgLum * 0.1 + 1)) + 0.1;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                half lumaAverageCurr = SAMPLE_TEXTURE2D(_LumaCurrTex, sampler_LumaCurrTex, float2(0, 0)).r;
                half lumaAdaptCurr = SAMPLE_TEXTURE2D(_LumaAdaptTex, sampler_LumaAdaptTex, float2(0, 0)).r;

                _Key = AutoKey(lumaAverageCurr);

                half3 color = mainTex * (_Key / (lumaAdaptCurr + 0.0001));
                color = Reinhard_extended(color, 1);
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}
