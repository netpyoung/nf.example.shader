Shader "vertex_anim_rat"
{
    // ref: https://torchinsky.me/shader-animation-unity/

    Properties
    {
        _MainTex("texture", 2D) = "white" {}

        _JumpSpeed("Jump Speed", float) = 10
        _JumpAmplitude("Jump Amplitude", float) = 0.18
        _JumpFrequency("Jump Frequency", float) = 2
        _JumpVerticalOffset("Jump Vertical Offset", float) = 0.33
        _TailExtraSwing("Tail Extra Swing", float) = 0.15
        _LegsAmplitude("Legs Amplitude", float) = 0.10
        _LegsFrequency("Legs Frequency", float) = 10
        _LegsPhaseOffset("Legs Phase Offset", float) = -1
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
            Name "VERTEX_ANIM_RAT"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;

            half _JumpSpeed;
            half _JumpAmplitude;
            half _JumpFrequency;
            half _JumpVerticalOffset;
            half _TailExtraSwing;
            half _LegsAmplitude;
            half _LegsFrequency;
            half _LegsPhaseOffset;
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

                float3 positionOS = IN.positionOS.xyz;

                float tailMask = smoothstep(0.6, 0.0, IN.uv.x) * _TailExtraSwing + _JumpAmplitude;
                float legsMask = smoothstep(0.4, 0.1, IN.uv.y);

                float bodyPos = max((abs(sin(_Time.y * _JumpSpeed + IN.uv.x * _JumpFrequency)) - _JumpVerticalOffset), 0);
                float legsPos = sin(_Time.y * _JumpSpeed * 2 + _LegsPhaseOffset + IN.uv.x * _LegsFrequency) * _LegsAmplitude;
                bodyPos *= tailMask;
                legsPos *= legsMask;

                positionOS.y += bodyPos;
                positionOS.z += legsPos;

                OUT.positionCS = TransformObjectToHClip(positionOS);
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
