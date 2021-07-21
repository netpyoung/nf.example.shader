Shader "Tone/Uncharted2"
{
    Properties
    {
        _MainTex("texture", 2D) = "white" {}

        [Toggle(IS_UNCHARTED2)]_IsUncharted2("Use Uncharted2?", Float) = 1
        _WhitePoint("_WhitePoint", Range(0, 20)) = 1
        _SoulderStrength("_SoulderStrength", Range(0, 1)) = 0.15
        _LinearStrength("_LinearStrength", Range(0, 1)) = 0.50
        _LinearAngle("_LinearAngle", Range(0, 1)) = 0.10
        _ToeStrength("_ToeStrength", Range(0, 1)) = 0.20
        _ToeNumerator("_ToeNumerator", Range(0, 1)) = 0.02
        _ToeDenominator("_ToeDenominator", Range(0, 1)) = 0.30
        _ExposureBias("_ExposureBias", Range(1, 20)) = 1

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
            Name "TONE_UNCHARTED2"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _ IS_UNCHARTED2

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            
            float _WhitePoint;
            float _SoulderStrength;
            float _LinearStrength;
            float _LinearAngle;
            float _ToeStrength;
            float _ToeNumerator;
            float _ToeDenominator;
            float _ExposureBias;
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

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                return OUT;
            }

            /*
            | param       |                          |
            |-------------|--------------------------|
            | A           | Soulder Strength         |
            | B           | Linear Strength          |
            | C           | Linear Angle             |
            | D           | Toe Strength             |
            | E           | Toe Numerator            |
            | F           | Toe Denominator          |
            | LinearWhite | Linear White Point Value |
            */
            float3 uncharted2_partial(float3 x, float A, float B, float C, float D, float E, float F)
            {
                return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - (E / F);
            }

            float3 uncharted2(float3 v, float white_point, float A, float B, float C, float D, float E, float F, float exposure_bias)
            {
                float3 x = v * exposure_bias;
                float3 curr = uncharted2_partial(x, A, B, C, D, E, F);
                float3 white_scale = 1.0 / uncharted2_partial(white_point, A, B, C, D, E, F);
                return curr * white_scale;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                #if IS_UNCHARTED2
                    half3 color = uncharted2(
                    mainTex,
                    _WhitePoint,
                    _SoulderStrength,
                    _LinearStrength,
                    _LinearAngle,
                    _ToeStrength,
                    _ToeNumerator,
                    _ToeDenominator,
                    _ExposureBias
                    );
                    return half4(color, 1);
                #else
                    return half4(mainTex, 1);
                #endif
            }
            ENDHLSL
        }
    }
}
