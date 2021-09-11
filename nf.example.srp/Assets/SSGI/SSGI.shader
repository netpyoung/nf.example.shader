Shader "srp/SSGI"
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
            // [(X) SSGI 관련 정리 (소스 포함)](http://eppengine.com/zbxe/programmig/2985)
            // - backup article: https://babytook.tistory.com/157
            
            NAME "PASS_SSGI_CALCUATE_OCULUSSION"

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
    
            float4 _MainTex_TexelSize;

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

            float3 ReadColor(in float2 uv)
            {
                return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).rgb;
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

            half4 frag(VStoFS IN) : SV_Target
            {
                float srcDepth = ReadDepth(IN.uv);
                float2 random = Random(IN.uv).xy;
                float pw = _MainTex_TexelSize.x * 0.5;
                float ph = _MainTex_TexelSize.y * 0.5;

                float AO = 0;
                float3 GI = 0;
                // 매 계산마다 1번씩 depth를 불러오니, 8 * 4 => 32번 depth를 불러온다
                for (int i = 0; i < 8; ++i)
                {
                    // 8번 루프(for) - 4번 계산(CalculateGI)
                    GI += CalculateGI(IN.uv, srcDepth, pw, ph, AO);
                    GI += CalculateGI(IN.uv, srcDepth, pw, -ph, AO);
                    GI += CalculateGI(IN.uv, srcDepth, -pw, ph, AO);
                    GI += CalculateGI(IN.uv, srcDepth, -pw, -ph, AO);

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

                float3 mainTex = ReadColor(IN.uv);

                return half4(GI, AO);
            }
            ENDHLSL
        }

        Pass // 1
        {
            NAME "PASS_SSGI_COMBINE"

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
                half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                float4 ambientOcclusionTex = SAMPLE_TEXTURE2D(_AmbientOcclusionTex, sampler_AmbientOcclusionTex, IN.uv).rgba;
                mainTex *= ambientOcclusionTex.a;
                mainTex += ambientOcclusionTex.rgb;
                return half4(mainTex, 1);
            }
            ENDHLSL
        }
    }
}
