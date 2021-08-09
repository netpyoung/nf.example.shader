Shader "Hidden/Sobel"
{
    HLSLINCLUDE
    ENDHLSL

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LineThickness("_LineThickness", Range(0.0005, 0.0025)) = 0.002
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

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float _LineThickness;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS   : SV_POSITION;
                float4 positionNDC  : TEXCOORD1;
                float2 uv           : TEXCOORD0;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);
                VertexPositionInputs vpi = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = vpi.positionCS;
                OUT.positionNDC = vpi.positionNDC;
                OUT.uv = IN.uv;
                return OUT;
            }

            float Sobel(float2 uv, float lineThickness)
            {
                float2 delta = float2(lineThickness, lineThickness);
                
                float m00 = LinearEyeDepth(SampleSceneDepth(uv + float2(-1.0, -1.0) * delta), _ZBufferParams);
                float m01 = LinearEyeDepth(SampleSceneDepth(uv + float2(0.0, -1.0) * delta), _ZBufferParams);
                float m02 = LinearEyeDepth(SampleSceneDepth(uv + float2(1.0, -1.0) * delta), _ZBufferParams);
                float m10 = LinearEyeDepth(SampleSceneDepth(uv + float2(-1.0, 0.0) * delta), _ZBufferParams);
                float m12 = LinearEyeDepth(SampleSceneDepth(uv + float2(1.0, 0.0) * delta), _ZBufferParams);
                float m20 = LinearEyeDepth(SampleSceneDepth(uv + float2(-1.0, 1.0) * delta), _ZBufferParams);
                float m21 = LinearEyeDepth(SampleSceneDepth(uv + float2(0.0, 1.0) * delta), _ZBufferParams);
                float m22 = LinearEyeDepth(SampleSceneDepth(uv + float2(1.0, 1.0) * delta), _ZBufferParams);

                // ref: https://en.wikipedia.org/wiki/Sobel_operator
                // Gx
                // -1 |  0 | +1
                // -2 |  0 | +2
                // -1 |  0 | -1
                // Gy
                // +1 | +2 | +1
                //  0 |  0 | 0
                // -1 | -2 | -1
                float Gx = 0;
                float Gy = 0;
                Gx += m00 * -1.0;
                Gx += m10 * -2.0;
                Gx += m20 * -1.0;
                Gx += m02 * 1.0;
                Gx += m12 * 2.0;
                Gx += m22 * 1.0;

                Gy += m00 * 1.0;
                Gy += m01 * 2.0;
                Gy += m02 * 1.0;
                Gy += m20 * -1.0;
                Gy += m21 * -2.0;
                Gy += m22 * -1.0;

                float G = sqrt(Gx * Gx + Gy * Gy);
                return G;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 pd = IN.positionNDC.xyz / IN.positionNDC.w; // perspectiveDivide
                half2 uv_Screen = pd.xy;

                half  sceneRawDepth = SampleSceneDepth(uv_Screen);
                half  sceneEyeDepth = LinearEyeDepth(sceneRawDepth, _ZBufferParams);

                float s = pow(1 - saturate(Sobel(IN.uv, _LineThickness)), 1);

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                return mainTex * s;
            }
            ENDHLSL
        }
    }
}
