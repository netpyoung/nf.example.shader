Shader "Hidden/Brightness"
{
    HLSLINCLUDE
    ENDHLSL

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AdaptionConstant("_AdaptionConstant", Float) = 1
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
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

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

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 mainTex = SAMPLE_TEXTURE2D_LOD(_MainTex, sampler_MainTex, IN.uv, 10).rgb;

                const half3 W = half3(0.2125, 0.7154, 0.0721);
                half luma = dot(mainTex, W);

                return half4(luma, 0, 0, 0);
            }
            ENDHLSL
        }

        Pass // 1
        {
            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_LumaPrevTex);    SAMPLER(sampler_LumaPrevTex);

            float _AdaptionConstant;

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
            };

            struct VStoFS
            {
                float4 positionCS   : SV_POSITION;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            float SensitivityOfRod(float y)
            {
                return 0.04 / (0.04 + y);
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half lumaAverageCurr = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(0, 0)).r;
                half lumaAdaptPrev = SAMPLE_TEXTURE2D(_LumaPrevTex, sampler_LumaPrevTex, float2(0, 0)).r;
                
                half _DeltaTime = unity_DeltaTime.x;
                half s = SensitivityOfRod(lumaAdaptPrev);
                half AdaptionConstant = s * 0.4 + (1 - s) * 0.1;

                half lumaAdaptCurr = lumaAdaptPrev
                    + (lumaAverageCurr - lumaAdaptPrev)
                    * (1.0 - exp(-_DeltaTime / AdaptionConstant * _AdaptionConstant));

                return half4(lumaAdaptCurr, 0, 0, 0);
            }
            ENDHLSL
        }
    }
}
