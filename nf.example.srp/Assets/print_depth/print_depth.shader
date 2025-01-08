Shader "srp/print_depth"
{
    SubShader
    {
        Cull Back
        ZWrite Off
        ZTest Off

        Pass // 0
        {
            NAME "PRINT_DEPTH"

            HLSLPROGRAM
            #pragma target 3.5

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #pragma vertex Vert
            #pragma fragment frag
            
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
