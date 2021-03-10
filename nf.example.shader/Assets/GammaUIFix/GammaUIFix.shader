Shader "GammaUIFix"
{
    Properties
    {
        [HideInInspector] _MainTex("UI Texture", 2D) = "white" {}
    }

    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_CameraColorTexture);
            SAMPLER(sampler_CameraColorTexture);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _CameraColorTexture_ST;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS      : SV_POSITION;
                float2 uv               : TEXCOORD0;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                ZERO_INITIALIZE(Varyings, OUT);

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            float4 frag(Varyings i) : SV_Target
            {
                float4 uiColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                uiColor.a = LinearToGamma22(uiColor.a);

                float4 mainColor = SAMPLE_TEXTURE2D(_CameraColorTexture, sampler_CameraColorTexture, i.uv);
                mainColor.rgb = LinearToGamma22(mainColor.rgb);

                float4 finalColor;
                finalColor.rgb = lerp(mainColor.rgb, uiColor.rgb, uiColor.a);
                finalColor.rgb = Gamma22ToLinear(finalColor.rgb);
                finalColor.a = 1;

                return finalColor;
            }
            ENDHLSL

        }
    }
}
