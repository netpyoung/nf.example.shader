Shader "Marschener"
{
    // ref: https://blog.naver.com/sorkelf/40186644136
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Normal]_NormalTex("Normal Map", 2D) = "bump" {}

        _HairShiftTex("Hair Shift", 2D) = "" {}
        _HairAlphaTex("Hair Alpha", 2D) = "" {}
        _HairSpeckMaskTex("Hair Mask", 2D) = "" {}

        _PrimaryShift("Primary Shift", Float) = 0
        _SecondaryShift("Secondary Shift", Float) = 0

        _S1Strength("Specular1 Strength", Float) = 1
        _S1Exponent("Specular1 Exponent", Range(10, 50)) = 20
        _S2Strength("Specular2 Strength", Float) = 1
        _S2Exponent("Specular2 Exponent", Range(10, 50)) = 20
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl" // For BlendNormal
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex);          SAMPLER(sampler_NormalTex);
            TEXTURE2D(_HairShiftTex);       SAMPLER(sampler_HairShiftTex);
            TEXTURE2D(_HairAlphaTex);       SAMPLER(sampler_HairAlphaTex);
            TEXTURE2D(_HairSpeckMaskTex);   SAMPLER(sampler_HairSpeckMaskTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;

                half _PrimaryShift;
                half _SecondaryShift;
                half _S1Strength;
                half _S1Exponent;
                half _S2Strength;
                half _S2Exponent;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangent      : TANGENT;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS      : SV_POSITION;
                float2 uv               : TEXCOORD0;

                float3 T                : TEXCOORD1;
                float3 B                : TEXCOORD2;
                float3 N                : TEXCOORD3;

                float3 positionWS       : TEXCOORD4;
            };


            // ----------
            inline void ExtractTBN(in half3 normalOS, in float4 tangent, inout half3 T, inout half3  B, inout half3 N)
            {
                N = TransformObjectToWorldNormal(normalOS);
                T = TransformObjectToWorldDir(tangent.xyz);
                B = cross(N, T) * tangent.w * unity_WorldTransformParams.w;
            }

            inline half3 CombineTBN(in half3 tangentNormal, in half3 T, in half3  B, in half3 N)
            {
                return mul(tangentNormal, float3x3(normalize(T), normalize(B), normalize(N)));
            }

            inline half3x3 GetTBN(in half3 T, in half3 B, in half3 N)
            {
                T = normalize(T);
                B = normalize(B);
                N = normalize(N);
                return float3x3(T, B, N);
            }

            Varyings  vert(Attributes IN)
            {
                Varyings OUT;
                ZERO_INITIALIZE(Varyings, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                ExtractTBN(IN.normalOS, IN.tangent, OUT.T, OUT.B, OUT.N);

                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            // --------------------
            inline half3 ShiftTangent(half3 T, half3 N, half shiftAmount)
            {
                return normalize(T + shiftAmount * N);
            }

            half SpecularStrand(half dotTH, half strength, half exponent)
            {
                // Strand : ����
                half sinTH = sqrt(1.0 - dotTH * dotTH);
                half dirAtten = smoothstep(-1.0, 0.0, dotTH);
                return dirAtten * strength * pow(sinTH, exponent);
            }
                
            half4 frag(Varyings IN) : SV_Target
            {
                half3 normalTex = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, IN.uv));

                Light light = GetMainLight();

// Sphere
                // T | r | 오른쪽
                // B | g | 위쪽
                // N | b | 직각

                // 논문에서 T. 방향은 머리를향한 위쪽 방향.
                // half3 T = normalize(IN.T);

                // Sphere에서는 B가 위쪽이므로 B로해야 원하는 방향이 나온다.
                half3 T = normalize(IN.B);
                //half3 N = CombineTBN(normalTex, IN.T, IN.B, IN.N);
                half3 N = normalize(IN.N);
                half3 L = normalize(light.direction);
                half3 V = TransformWorldToViewDir(IN.positionWS);
                half3 H = normalize(L + V);

                half NdotL = max(0.0, dot(N, L));

                half shiftTexVal = SAMPLE_TEXTURE2D(_HairShiftTex, sampler_HairShiftTex, IN.uv).r - 0.5;
                half3 T1 = ShiftTangent(T, N, _PrimaryShift + shiftTexVal);
                half3 T2 = ShiftTangent(T, N, _SecondaryShift + shiftTexVal);

                half3 specular1 = SpecularStrand(dot(T1, H), _S1Strength, _S1Exponent);
                half3 specular2 = SpecularStrand(dot(T2, H), _S2Strength, _S2Exponent);

                half3 specular2Mask = SAMPLE_TEXTURE2D(_HairSpeckMaskTex, sampler_HairSpeckMaskTex, IN.uv).rgb;
                half3 specular = specular1 + specular2 * specular2Mask;

                //half specularAttenuation = saturate(1.75 * NdotL + 0.25);
                //specular *= specularAttenuation;

                half3 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                
                //half3 diffuse = lerp(0.25, 1, NdotL);
                half3 diffuse = saturate(0.75 * NdotL + 0.25);;
                
                half4 finalColor = half4(diffuse * mainColor + specular, 0);
                finalColor.a = SAMPLE_TEXTURE2D(_HairAlphaTex, sampler_HairAlphaTex, IN.uv).r;

                return finalColor;
            }
            ENDHLSL
        }
    }
}
