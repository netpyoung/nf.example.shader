Shader "srp/GammaUIFix"
{
    Properties
    {
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
        }

        Cull Off
        ZWrite Off
        ZTest Always
        
        HLSLINCLUDE
        #pragma target 3.5
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
        #pragma vertex Vert
        #pragma fragment frag
        ENDHLSL

        Pass // 0
        {
            NAME "GAMMA_UI_FIX"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            TEXTURE2D(_CameraColorTexture);
            SAMPLER(sampler_CameraColorTexture);
        
            float4 frag(Varyings IN) : SV_Target
            {
return 1;
                // float4 uiColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.texcoord);
                // float3 blitTex = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord).rgb;
                float4 uiColor = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord);
return float4(1 - uiColor.rgb, 1);
                uiColor.a = LinearToGamma22(uiColor.a);

                float4 mainColor = SAMPLE_TEXTURE2D(_CameraColorTexture, sampler_CameraColorTexture, IN.texcoord);
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
