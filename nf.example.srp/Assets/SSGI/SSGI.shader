Shader "srp/SSGI"
{
    Properties
    {
        _RandTex("_RandTex", 2D) = "white" {}
    }

    SubShader
    {
        HLSLINCLUDE
        #pragma target 3.5
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        #pragma vertex Vert
        #pragma fragment frag
        ENDHLSL

        Pass // 0
        {
            // [(X) SSGI 관련 정리 (소스 포함)](http://eppengine.com/zbxe/programmig/2985)
            // - backup article: https://babytook.tistory.com/157
            
            NAME "PASS_SSGI_CALCUATE_OCULUSSION"

            HLSLPROGRAM
            TEXTURE2D(_RandTex);
            SAMPLER(sampler_RandTex);
    
            float4 _blitTex_TexelSize;


            inline float2 Random(in float2 uv)
            {
                return SAMPLE_TEXTURE2D(_RandTex, sampler_RandTex, uv).rg;
            }

            float ReadDepth(in float2 uv)
            {
                half sceneRawDepth = SampleSceneDepth(uv);
                half scene01Depth = Linear01Depth(sceneRawDepth, _ZBufferParams);
                return scene01Depth;
            }

            float3 ReadColor(in float2 uv)
            {
                half3 blitTex = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, uv).rgb;
                return blitTex;
            }

            float CompareDepth(in float depth1, in float depth2)
            {

                float diff = (depth1 - depth2) * 100;   //depth difference (0-100)
                float gdisplace = 0.2;                  //gauss bell center
                float garea = 2.0;                      //gauss bell width 2

                //reduce left bell width to avoid self-shadowing
                if (diff < gdisplace)
                {
                    garea = 0.2;
                }
                
                float gauss = pow(2.7182, -2 * (diff - gdisplace) * (diff - gdisplace) / (garea * garea));
                return gauss;
            }

            float3 CalculateGI(in float2 uv, float depth, float dw, float dh, inout float ao)
            {
                float temp = 0;
                float3 bleed = 0;
                float coordw = uv.x + dw / depth;
                float coordh = uv.y + dh / depth;

                if ((0.0 < coordw && coordw < 1.0) && (0.0 < coordh && coordh < 1.0))
                {
                    float2 coord = float2(coordw, coordh);
                    temp = CompareDepth(depth, ReadDepth(coord));
                    bleed = ReadColor(coord);
                }
                ao += temp;
                return temp * bleed;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float srcDepth = ReadDepth(IN.texcoord);
                float2 random = Random(IN.texcoord).xy;
                float pw = _blitTex_TexelSize.x * 0.5;
                float ph = _blitTex_TexelSize.y * 0.5;

                float AO = 0;
                float3 GI = 0;
                // 매 계산마다 1번씩 depth를 불러오니, 8 * 4 => 32번 depth를 불러온다
                for (int i = 0; i < 8; ++i)
                {
                    // 8번 루프(for) - 4번 계산(CalculateGI)
                    GI += CalculateGI(IN.texcoord, srcDepth, pw, ph, AO);
                    GI += CalculateGI(IN.texcoord, srcDepth, pw, -ph, AO);
                    GI += CalculateGI(IN.texcoord, srcDepth, -pw, ph, AO);
                    GI += CalculateGI(IN.texcoord, srcDepth, -pw, -ph, AO);

                    //sample jittering:
                    pw += random.x * 0.0005;
                    ph += random.y * 0.0005;

                    //increase sampling area:
                    pw *= 1.4;
                    ph *= 1.4;
                }

                const int SAMPLE_COUNT = 32; // 4 * 8
                AO /= SAMPLE_COUNT;
                AO = saturate(1 - AO);
                GI /= SAMPLE_COUNT;
                GI *= 0.6;

                return half4(GI, AO);
            }
            ENDHLSL
        }

        Pass // 1
        {
            NAME "PASS_SSGI_COMBINE"

            HLSLPROGRAM
            TEXTURE2D(_AmbientOcclusionTex);
            SAMPLER(sampler_AmbientOcclusionTex);

            half4 frag(Varyings IN) : SV_Target
            {
                half3 blitTex = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord).rgb;
                float4 ambientOcclusionTex = SAMPLE_TEXTURE2D(_AmbientOcclusionTex, sampler_AmbientOcclusionTex, IN.texcoord).rgba;
                blitTex *= ambientOcclusionTex.a;
                blitTex += ambientOcclusionTex.rgb;
                return half4(blitTex, 1);
            }
            ENDHLSL
        }
    }
}
