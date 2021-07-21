Shader "Filter/Radical"
{
    // ref: https://forum.unity.com/threads/radial-blur.31970/#post-209514

    Properties
    {
        [NoScaleOffset] _MainTex("texture", 2D) = "white" {}
        _TexelScale("_TexelScale", Range(0.0, 1.5)) = 1
        _BlurStrength("_BlurStrength", Range(0, 1)) = 1
        
        _CenterPosX("_CenterPosX", Range(0, 1)) = 0.5
        _CenterPosY("_CenterPosY", Range(0, 1)) = 0.5
        [Toggle(IS_BLUR)]_IsBlur("Apply Blur?", Float) = 1

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
            Name "FILTER_RADICAL"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _ IS_BLUR

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            half _TexelScale;
            half _BlurStrength;
            half _CenterPosX;
            half _CenterPosY;
            CBUFFER_END

            const static half SAMPLES[10] = {
                -0.08, -0.05, -0.03, -0.02, -0.01,
                +0.01, +0.02, +0.03, +0.05, +0.08
            };

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float2 uv            : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float2 uv            : TEXCOORD0;
                float2 dir            : TEXCOORD1;
                float dist            : TEXCOORD2;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;

                OUT.dir = half2(_CenterPosX, _CenterPosY) - IN.uv;
                OUT.dist = sqrt(OUT.dir.x * OUT.dir.x + OUT.dir.y * OUT.dir.y);
                OUT.dir /= OUT.dist;

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                #if IS_BLUR
                    half2 dir = IN.dir * _TexelScale;

                    half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                    half3 color = mainTex;
                    for (int i = 0; i < 10; ++i)
                    {
                        half2 uv = IN.uv + SAMPLES[i] * dir;
                        color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).rgb;
                    }

                    color *= 1.0 / 11.0;

                    half weight = saturate(IN.dist * _BlurStrength);

                    return half4(lerp(mainTex, color, weight).rgb, 1);
                #else
                    return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                #endif
            }
            ENDHLSL
        }
    }
}
