Shader "srp/print_depth"
{
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
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

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;

                #if UNITY_UV_STARTS_AT_TOP
                    // _MainTex_TexelSize.xy    : x= 1/°¡·Î, y= 1/¼¼·Î.
                    // UNITY_UV_STARTS_AT_TOP   : DirectX == 1, OpenGL == 0.
                    // _MainTex_TexelSize.y < 0 : antialiasing On.
                    if (_MainTex_TexelSize.y < 0)
                    {
                        OUT.uv.y = 1 - OUT.uv.y;
                    }
                #endif

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half depth = SampleSceneDepth(IN.uv);

                half linear01Depth = Linear01Depth(depth, _ZBufferParams);

                return linear01Depth;
            }
            ENDHLSL
        }
    }
}
