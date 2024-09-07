Shader "srp/SSAO_noblur"
{
    Properties
    {
        _RandTex("_RandTex", 2D) = "white" {}
    }

    SubShader
    {
        Cull Back
        ZWrite Off
        ZTest Off

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
            // [(X) SSAO (Screen Space Ambient Occlusion) 처리 기법(소스포함)](http://eppengine.com/zbxe/programmig/2982)
            // - backup article: https://babytook.tistory.com/158
            
            NAME "PASS_SSAO_CALCUATE_OCULUSSION"

            HLSLPROGRAM
            TEXTURE2D(_RandTex);
            SAMPLER(sampler_RandTex);
    
            //float4 _CameraDepthTexture_TexelSize;

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

            float CompareDepth(in float depth1, in float depth2, inout int far)
            {

                float diff = (depth1 - depth2) * 100;   //depth difference (0-100)
                float gdisplace = 0.2;                  //gauss bell center
                float garea = 2.0;                      //gauss bell width 2

                //reduce left bell width to avoid self-shadowing
                if (diff < gdisplace)
                {
                    garea = 0.1;
                }
                else
                {
                    far = 1;
                }

                float gauss = pow(2.7182, -2 * (diff - gdisplace) * (diff - gdisplace) / (garea * garea));
                return gauss;
            }

            float CalculateAO(in float2 uv, float depth, float dw, float dh)
            {
                float temp1 = 0;
                float temp2 = 0;
                float coordw1 = uv.x + dw / depth;
                float coordh1 = uv.y + dh / depth;
                float coordw2 = uv.x - dw / depth;
                float coordh2 = uv.y - dh / depth;

                if ((0.0 < coordw1 && coordw1 < 1.0) && (0.0 < coordh1 && coordh1 < 1.0))
                {
                    float2 coord1 = float2(coordw1, coordh1);
                    float2 coord2 = float2(coordw2, coordh2);

                    int far = 0;
                    temp1 = CompareDepth(depth, ReadDepth(coord1), far);

                    //DEPTH EXTRAPOLATION:
                    if (far > 0)
                    {
                        temp2 = CompareDepth(ReadDepth(coord2), depth, far);
                        temp1 += (1.0 - temp1) * temp2;
                    }
                }
                return temp1;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float srcDepth = ReadDepth(IN.texcoord); // depth center
                float2 random = Random(IN.texcoord).xy;
                float pw = _CameraDepthTexture_TexelSize.x * 0.5;
                float ph = _CameraDepthTexture_TexelSize.y * 0.5;

                float AO = 0;

                // 매 계산마다 최대 2번씩 depth를 불러오니, 4 * 8 * 2 => 64번 depth를 불러온다
                for (int i = 0; i < 4; ++i)
                {
                    // 4번 루프(for) - 8번 계산(CalculateAO)
                    AO += CalculateAO(IN.texcoord, srcDepth, pw, ph);
                    AO += CalculateAO(IN.texcoord, srcDepth, pw, -ph);
                    AO += CalculateAO(IN.texcoord, srcDepth, -pw, ph);
                    AO += CalculateAO(IN.texcoord, srcDepth, -pw, -ph);

                    AO += CalculateAO(IN.texcoord, srcDepth, pw * 1.2, 0);
                    AO += CalculateAO(IN.texcoord, srcDepth, -pw * 1.2, 0);
                    AO += CalculateAO(IN.texcoord, srcDepth, 0, ph * 1.2);
                    AO += CalculateAO(IN.texcoord, srcDepth, 0, -ph * 1.2);

                    //sample jittering:
                    pw += random.x * 0.0007;
                    ph += random.y * 0.0007;

                    //increase sampling area:
                    pw *= 1.7;
                    ph *= 1.7;
                }

                const int SAMPLE_COUNT = 32; // 4 * 8
                AO /= SAMPLE_COUNT;
                AO = saturate(1 - AO);
                AO = 0.3 + AO * 0.7;

                return half4(AO.xxx, 1);
            }
            ENDHLSL
        }

        Pass // 1
        {
            NAME "PASS_SSAO_COMBINE"

            HLSLPROGRAM
            TEXTURE2D(_AmbientOcclusionTex);
            SAMPLER(sampler_AmbientOcclusionTex);

            half4 frag(Varyings IN) : SV_Target
            {
                half4 blitTex = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord);
                float ambientOcclusionTex = SAMPLE_TEXTURE2D(_AmbientOcclusionTex, sampler_AmbientOcclusionTex, IN.texcoord).r;
                // blitTex *= (1 - ambientOcclusionTex);
                blitTex *= ambientOcclusionTex;
                return blitTex;
            }
            ENDHLSL
        }
    }
}
