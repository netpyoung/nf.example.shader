Shader "Hidden/Uber"
{
    HLSLINCLUDE
    ENDHLSL

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        Pass // 0
        {
            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
            #pragma multi_compile_local_fragment _ _UBER_A
            #pragma multi_compile_local_fragment _ _UBER_B

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);
                VertexPositionInputs vpi = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = vpi.positionCS;
                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                float3 color = float3(0, 0, 0);

#if _UBER_A
                color.r = 1;
#endif

#if _UBER_B
                color.g = 1;
#endif
                return float4(color, 1);
            }
            ENDHLSL
        }
    }
}
