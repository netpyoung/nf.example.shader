Shader "Hidden/Uber"
{
    HLSLINCLUDE
    ENDHLSL

    Properties
    {
    }

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
            HLSLPROGRAM
            #pragma multi_compile_local_fragment _ _UBER_A
            #pragma multi_compile_local_fragment _ _UBER_B

            half4 frag(Varyings IN) : SV_Target
            {
                float3 color = float3(0, 0, 0);

#if _UBER_A
                color.r = 1;
#endif // _UBER_A

#if _UBER_B
                color.g = 1;
#endif // _UBER_B
                return float4(color, 1);
            }
            ENDHLSL
        }
    }
}
