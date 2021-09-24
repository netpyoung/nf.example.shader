Shader "example/Sky_Cloud"
{
    Properties
    {
        _MainTex("texture", 2D) = "black" {}
        _NoiseTex("_NoiseTex", 2D) = "black" {}
        _Translation("_Translation", Float) = 1
        _Scale("_Scale", Float) = 1
        _Brightness("_Brightness", Float) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Background+2"
            "RenderType" = "Background"
            "ForceNoShadowCasting" = "True"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Cull Off
            ZWrite Off
            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);    SAMPLER(sampler_NoiseTex);
        
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;

            float _Translation;
            float _Scale;
            float _Brightness;
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

            half4 frag(VStoFS IN) : SV_Target
            {
                IN.uv.x += _Translation;

                float4 perturbValue = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.uv);

                perturbValue = perturbValue * _Scale;
                perturbValue.xy = perturbValue.xy + IN.uv.xy + _Translation;

                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, perturbValue.xy);
                clip(mainTex.r - 0.1);

                mainTex *= _Brightness;
                return mainTex;
            }
            ENDHLSL
        }
    }
}
