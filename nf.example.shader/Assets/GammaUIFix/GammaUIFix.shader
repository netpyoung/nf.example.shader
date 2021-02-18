Shader "GammaUIFix"
{
    Properties
    {
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

            TEXTURE2D(_UITex);
            SAMPLER(sampler_UITex);
            TEXTURE2D(_CameraColorTexture);
            SAMPLER(sampler_CameraColorTexture);

            CBUFFER_START(UnityPerMaterial)
                float4 _UITex_ST;
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
                Varyings OUT = (Varyings)0;;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _UITex);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 uiColor = SAMPLE_TEXTURE2D(_UITex, sampler_UITex, IN.uv); //ui in lighter color
                uiColor.a = LinearToGamma22(uiColor.a); //make ui alpha in lighter color

                half4 gameColor = SAMPLE_TEXTURE2D(_CameraColorTexture, sampler_CameraColorTexture, IN.uv); //3d in normal color
                gameColor.rgb = LinearToGamma22(gameColor.rgb); //make 3d in lighter color

                half4 finalColor;
                finalColor.rgb = lerp(gameColor.rgb, uiColor.rgb, uiColor.a); //do linear blending
                finalColor.rgb = Gamma22ToLinear(finalColor.rgb); //make result normal color
                finalColor.a = 1;

                return uiColor;
            }
            ENDHLSL
        }
    }
}
