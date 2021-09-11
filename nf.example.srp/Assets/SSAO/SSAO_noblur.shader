Shader "srp/SSAO_noblur"
{
    Properties
    {
        [HideInInspector] _MainTex("UI Texture", 2D) = "white" {}
        _RandTex("_RandTex", 2D) = "white" {}
    }

    SubShader
    {
        Pass // 0
        {
            // [(X) SSAO (Screen Space Ambient Occlusion) 처리 기법(소스포함)](http://eppengine.com/zbxe/programmig/2982)
            // - backup article: https://babytook.tistory.com/158
            
            NAME "PASS_SSAO_CALCUATE_OCULUSSION"

            Cull Back
            ZWrite Off
            ZTest Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_RandTex);    SAMPLER(sampler_RandTex);
    
            float4 _CameraDepthTexture_TexelSize;

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
                return OUT;
            }

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

            half4 frag(VStoFS IN) : SV_Target
            {
                float srcDepth = ReadDepth(IN.uv); // depth center
                float2 random = Random(IN.uv).xy;
                float pw = _CameraDepthTexture_TexelSize.x * 0.5;
                float ph = _CameraDepthTexture_TexelSize.y * 0.5;

                float AO = 0;

                // 매 계산마다 최대 2번씩 depth를 불러오니, 4 * 8 * 2 => 64번 depth를 불러온다
                for (int i = 0; i < 4; ++i)
                {
                    // 4번 루프(for) - 8번 계산(CalculateAO)
                    AO += CalculateAO(IN.uv, srcDepth, pw, ph);
                    AO += CalculateAO(IN.uv, srcDepth, pw, -ph);
                    AO += CalculateAO(IN.uv, srcDepth, -pw, ph);
                    AO += CalculateAO(IN.uv, srcDepth, -pw, -ph);

                    AO += CalculateAO(IN.uv, srcDepth, pw * 1.2, 0);
                    AO += CalculateAO(IN.uv, srcDepth, -pw * 1.2, 0);
                    AO += CalculateAO(IN.uv, srcDepth, 0, ph * 1.2);
                    AO += CalculateAO(IN.uv, srcDepth, 0, -ph * 1.2);

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

            Cull Off
            ZWrite Off
            ZTest Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
            TEXTURE2D(_AmbientOcclusionTex);       SAMPLER(sampler_AmbientOcclusionTex);

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
                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float ambientOcclusionTex = SAMPLE_TEXTURE2D(_AmbientOcclusionTex, sampler_AmbientOcclusionTex, IN.uv).r;
                // mainTex *= (1 - ambientOcclusionTex);
                mainTex *= ambientOcclusionTex;
                return mainTex;
            }
            ENDHLSL
        }
    }
}
