Shader "Gears-Beam"
{
    // ref:
    // - https://lexdev.net/tutorials/case_studies/gears_hammerofdawn.html
    // - https://github.com/LexdevTutorials/GearsHammerOfDawn

    Properties
    {
        _Color("Color", Color) = (1, 0, 0, 1)
        [HDR]_Emission("Emission", Color) = (1, 1, 1, 1)

        //0 = start of the sequence (small beam at the bottom), 1 = end of sequence (large beam)
        _Sequence("Sequence Value", Range(0,1)) = 0.1

        //Changes the width of the whole beam
        _Width("Width Multiplier", Range(1,3)) = 2

        //Noise
        _NoiseFrequency("Noise Frequency", Range(1,100)) = 50.0
        _NoiseLength("Noise Length", Range(0.01,1.0)) = 0.25
        _NoiseIntensity("Noise Intensity", Range(0,0.1)) = 0.02
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                half4 _Emission;

                half _Sequence;
                half _Width;
                half _NoiseFrequency;
                half _NoiseLength;
                half _NoiseIntensity;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normal       : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 N            : TEXCOORD1;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;


                half beamHeight = 20;
                half pi = 3.141;

                half scaledSeq = (1.0f - _Sequence) * 2.0f - 1.0f; //Invert the sequence value and scale it to [-1;1]
                half scaledHeightMax = scaledSeq * beamHeight; //The sequence value scaled with the height of the beam object
                half cosVal = cos(pi * (IN.positionOS.z / beamHeight - scaledSeq));

                half width = lerp(0.05f * (beamHeight - scaledHeightMax + 0.5f), cosVal, pow(smoothstep(scaledHeightMax - 8.0f, scaledHeightMax, IN.positionOS.z), 0.1f));
                width = lerp(width, 0.4f, smoothstep(scaledHeightMax, scaledHeightMax + 10.0f, IN.positionOS.z));

                IN.positionOS.xy *= width * _Width;
                IN.positionOS.xy += sin(_Time.y * _NoiseFrequency + IN.positionOS.z * _NoiseLength) * _NoiseIntensity * _Sequence;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.N = TransformObjectToWorldDir(IN.normal);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                Light light = GetMainLight();
                half3 L = light.direction;
                half3 N = normalize(IN.N);

                half NdotL = max(0, dot(N, L));

                half4 finalColor = _Color * NdotL + _Emission;
                return finalColor;
            }
            ENDHLSL
        }
    }
}
