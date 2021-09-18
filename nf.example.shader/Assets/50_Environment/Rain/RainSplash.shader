Shader "Rain/RainSplash"
{
    Properties
    {
        _MainTex("texture", 2D) = "white" {}
        _Intensity("Intensity", Range(0.5, 4.0)) = 1.5
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

        Pass
        {
            Name "TEXTURE_COLOR"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Cull Back
            ZWrite Off
            Blend SrcAlpha OneMinusSrcColor

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float _Intensity;
            float4 _MainTex_ST;
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
                float visibility     : TEXCOORD1;
            };
            
            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;

                half timeVal = frac(_Time.z * 0.5 + OUT.uv.x) * 2.0;
                OUT.uv.x = OUT.uv.x / 6 + floor(timeVal * 6) / 6;
                OUT.visibility = saturate(1.0 - timeVal) * _Intensity;

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                 return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * IN.visibility;
            }
            ENDHLSL
        }
    }
}
