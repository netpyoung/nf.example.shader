Shader "srp/HelloSRP"
{
    SubShader
    {
        Cull Back
        ZWrite Off
        ZTest Off

        HLSLINCLUDE
        #pragma target 3.5
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
        #pragma vertex Vert
        #pragma fragment frag
        ENDHLSL

        Pass // 0
        {
            NAME "HELLO_SRP"

            HLSLPROGRAM
            half4 frag(Varyings IN) : SV_Target
            {
                float3 blitTex = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord).rgb;
                return half4(1 - blitTex, 1);
            }
            ENDHLSL
        }
    }
}
