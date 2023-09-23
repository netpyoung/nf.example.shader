Shader "srp/print_depth"
{
    SubShader
    {
        Pass // 0
        {
            NAME "PRINT_DEPTH"

            Cull Back
            ZWrite Off
            ZTest Always

            HLSLPROGRAM
            #pragma target 3.5

            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #pragma vertex Vert
            
            half4 frag(Varyings IN) : SV_Target
            {
                half depth = SampleSceneDepth(IN.texcoord);

                half linear01Depth = Linear01Depth(depth, _ZBufferParams);

                return linear01Depth;
            }
            ENDHLSL
        }
    }
}
