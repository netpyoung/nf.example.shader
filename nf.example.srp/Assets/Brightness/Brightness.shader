Shader "Hidden/Brightness"
{
    HLSLINCLUDE
    ENDHLSL

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AdaptionRate("_AdaptionRate", Float) = 1
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

            CBUFFER_START(UnityPerMaterial)
            float _LineThickness;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS   : SV_POSITION;
                float4 positionNDC  : TEXCOORD1;
                float2 uv           : TEXCOORD0;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);
                VertexPositionInputs vpi = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = vpi.positionCS;
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                const half3 W = half3(0.2125, 0.7154, 0.0721);
                half3 mainTex = SAMPLE_TEXTURE2D_LOD(_MainTex, sampler_MainTex, IN.uv, 10).rgb;
                return dot(mainTex, W);
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

            CBUFFER_START(UnityPerMaterial)
            float _AdaptionRate;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
            };

            struct VStoFS
            {
                float4 positionCS   : SV_POSITION;
                float4 positionNDC  : TEXCOORD1;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);
                VertexPositionInputs vpi = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = vpi.positionCS;
                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half lumaCurr = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(0, 0)).r;
                half lumaPrev = SAMPLE_TEXTURE2D(_LumaPrevTex, sampler_LumaPrevTex, float2(0, 0)).r;

                half _DeltaTime = unity_DeltaTime.x;

                half lumaAdapt = lumaPrev
                    + (lumaCurr - lumaPrev)
                    * (1.0 - exp2(-_AdaptionRate * _DeltaTime))
                    * (clamp((lumaCurr - lumaPrev), 0, 1) * -0.8 + 1);
                
                // half lumaAdapt = lerp(lumaPrev, lumaCurr, _AdaptionRate * _DeltaTime);
                return lumaAdapt;
            }
            ENDHLSL
        }
    }
}
