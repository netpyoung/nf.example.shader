Shader "Gears-Beam"
{
    // ref:
    // - https://lexdev.net/tutorials/case_studies/gears_hammerofdawn.html
    // - https://github.com/LexdevTutorials/GearsHammerOfDawn

    Properties
    {
        [HDR] _Color("Color", Color) = (1, 0, 0, 1)

        _Sequence("Sequence Value", Range(0,1)) = 0.1
        _Width("Width Multiplier", Range(1,3)) = 2
        _NoiseFrequency("Noise Frequency", Range(1,100)) = 50.0
        _NoiseLength("Noise Length", Range(0.01,1.0)) = 0.25
        _NoiseIntensity("Noise Intensity", Range(0,0.1)) = 0.02
    }

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
            Name "GEARS_BEAM"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            CBUFFER_START(UnityPerMaterial)
                half4 _Color;

                half _Sequence;
                half _Width;
                half _NoiseFrequency;
                half _NoiseLength;
                half _NoiseIntensity;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float3 normal       : NORMAL;
            };

            struct VStoFS
            {
                float4 positionCS  : SV_POSITION;
                float3 N            : TEXCOORD1;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                half beamHeight = 20;
                half pi = 3.141;

                // [-1, 1]
                half scaledSeq = (1.0f - _Sequence) * 2.0f - 1.0f;

                // [-beamHeight, beamHeight]
                half scaledHeightMax = scaledSeq * beamHeight;

                // 높이 비율에 대한 cos값.
                half cosVal = cos(pi * (IN.positionOS.z / beamHeight - scaledSeq));

                half width = lerp(
                    0.05f * (beamHeight - scaledHeightMax + 0.5f),
                    cosVal,
                    pow(smoothstep(scaledHeightMax - 8.0f, scaledHeightMax, IN.positionOS.z), 0.1f)
                );

                width = lerp(
                    width,
                    0.4f,
                    smoothstep(scaledHeightMax, scaledHeightMax + 10.0f, IN.positionOS.z)
                );

				// 넓이 조정.
                IN.positionOS.xy *= width * _Width;
				
				// 좌우 진폭조정.
                IN.positionOS.xy += sin(_Time.y * _NoiseFrequency + IN.positionOS.z * _NoiseLength) * _NoiseIntensity * _Sequence;

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.N = TransformObjectToWorldDir(IN.normal);

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                Light light = GetMainLight();
                half3 L = light.direction;
                half3 N = normalize(IN.N);

                half NdotL = max(0, dot(N, L));

                half4 finalColor = _Color * NdotL;
                return finalColor;
            }
            ENDHLSL
        }
    }
}
