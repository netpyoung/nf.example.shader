Shader "HelloSRP"
{
    Properties
    {
        [HideInInspector] _MainTex("UI Texture", 2D) = "white" {}
    }

    SubShader
    {
        Pass // 0
        {
            NAME "HELLO_SRP"

            Cull Back
            ZWrite Off
            ZTest Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #pragma vertex Vert

            TEXTURE2D_X(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);

            half4 frag(Varyings IN) : SV_Target
            {
                float3 colorTex = SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, IN.texcoord).rgb;
                return half4(1 - colorTex, 1);
            }
            ENDHLSL
        }
    }
}
