Shader "srp/print_depth"
{
    Properties
    {
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
                "Queue" = "Geometry"
                "RenderType" = "Opaque"
            }

            
            Cull Off
            ZTest Always
            ZWrite Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            half4 _MainTex_TexelSize;

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                ZERO_INITIALIZE(Varyings, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;

#if UNITY_UV_STARTS_AT_TOP
                // _MainTex_TexelSize.xy    : x= 1/가로, y= 1/세로.
                // UNITY_UV_STARTS_AT_TOP   : DirectX == 1, OpenGL == 0.
                // _MainTex_TexelSize.y < 0 : antialiasing On.
                if (_MainTex_TexelSize.y < 0)
                {
                    OUT.uv.y = 1 - OUT.uv.y;
                }
#endif

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half depth = SampleSceneDepth(IN.uv);

                half linear01Depth = Linear01Depth(depth, _ZBufferParams);

                return linear01Depth;
            }
            ENDHLSL
        }
    }
}
