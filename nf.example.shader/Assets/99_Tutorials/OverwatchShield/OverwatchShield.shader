Shader "OverwatchShield"
{
    // ref:
    // - https://lexdev.net/tutorials/case_studies/overwatch_shield.html
    // - https://github.com/LexdevTutorials/OverwatchShield

    Properties
    {
        _PulseTex ("Texture", 2D) = "white" {}
        _Color("Color", Color) = (1, 1, 1, 1)

        _PulseIntensity("Hex Pulse Intensity", float) = 3.0
        _PulseTimeScale("Hex Pulse Time Scale", float) = 2.0
        _PulsePosScale("Hex Pulse Position Scale", float) = 50.0
        _PulseTexOffsetScale("Hex Pulse Texture Offset Scale", float) = 1.5
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }
        
        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Cull Off
            Blend SrcAlpha One

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_PulseTex);
            SAMPLER(sampler_PulseTex);

            CBUFFER_START(UnityPerMaterial)
                half4 _PulseTex_ST;
                half4 _Color;

                half _PulseIntensity;
                half _PulseTimeScale;
                half _PulsePosScale;
                half _PulseTexOffsetScale;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float4 positionOS   : TEXCOORD1;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT = (VStoFS) 0;

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _PulseTex);
                OUT.positionOS = IN.positionOS;

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                
                half4 pulseColor = SAMPLE_TEXTURE2D(_PulseTex, sampler_PulseTex, IN.uv);

                half horizontalDist = abs(IN.positionOS.x);

                half4 pulseTerm = pulseColor * _Color * _PulseIntensity;
                pulseTerm *= abs(
                    sin(_Time.y * _PulseTimeScale               // 시간 빠르기.
                        - horizontalDist * _PulsePosScale       // 좌우 이동.
                        + pulseColor.r * _PulseTexOffsetScale   // r값에 대한 가중치.
                    )
                );

                // Edge Pulse
                half4 finalColor = half4(pulseTerm.rgb, _Color.a);
                return finalColor;
            }
            ENDHLSL
        }
    }
}
