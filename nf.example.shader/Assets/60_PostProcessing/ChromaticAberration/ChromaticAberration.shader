Shader "PostProcess/ChromaticAberration"
{
    Properties
    {
        [NoScaleOffset] _MainTex("texture", 2D) = "white" {}
        [Toggle(IS_CHROMATIC_ABERRATION)]_IsChromaticAberration("Apply ChromaticAberration?", Float) = 1
        _ParamK("_ParamK", Float) = 1
        _ParamKcube("_ParamKcube", Float) = 1
            
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
            Name "FILTER_AVERAGE"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _ IS_CHROMATIC_ABERRATION

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            float _ParamK;
            float _ParamKcube;

            CBUFFER_START(UnityPerMaterial)
            float2 _MainTex_TexelSize;
            half _TexelScale;
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
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                #if IS_CHROMATIC_ABERRATION
                    half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                    half k = _ParamK;
                    half kcube = _ParamKcube;

                    float2 centerUV = (IN.uv - 0.5);
                    half r2 = dot(centerUV, centerUV);
                    half f = 0;
                    if (kcube == 0)
                    {
                        f = 1 + r2 * k;
                    }
                    else
                    {
                        f = 1 + r2 * (k + kcube * sqrt(r2));
                    }

                    float2 chromaticUV = 0.5 + centerUV * f;
                    half3 final_chromatic = half3(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, chromaticUV).rg, mainTex.b);

                    return half4(final_chromatic, 1);
                #else
                    return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                #endif
            }
            ENDHLSL
        }
    }
}
