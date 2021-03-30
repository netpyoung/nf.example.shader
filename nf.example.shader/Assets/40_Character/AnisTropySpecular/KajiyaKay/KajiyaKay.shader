Shader "KajiyaKay"
{
    // ref: https://blog.naver.com/sorkelf/40185948507
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Normal]_NormalTex("Normal Map", 2D) = "bump" {}
        _HairShiftTex("Hair Shift", 2D) = "" {}
        _HairAlphaTex("Hair Alpha", 2D) = "" {}
        _Kd("Diffuse Strength", Float) = 1
        _Ks("Specular Strength", Float) = 1
        _SpecularExponent("Specular Exponent", Range(10, 50)) = 20
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

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex);      SAMPLER(sampler_NormalTex);
            TEXTURE2D(_HairShiftTex);   SAMPLER(sampler_HairShiftTex);
            TEXTURE2D(_HairAlphaTex);   SAMPLER(sampler_HairAlphaTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _HairShiftTex_ST;
                float4 _HairAlphaTex_ST;
                half _Ks;
                half _Kd;
                half _SpecularExponent;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangent      : TANGENT;
                float2 uv           : TEXCOORD0;
            };

            struct VStoFS
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

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                ExtractTBN(IN.normalOS, IN.tangent, OUT.T, OUT.B, OUT.N);

                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
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
                half3 N = CombineTBN(normalTex, IN.T, IN.B, IN.N);
                half3 L = normalize(light.direction);
                half3 V = TransformWorldToViewDir(IN.positionWS);
                half3 H = normalize(L + V);

                half NdotL = max(0.0, dot(N, L));
                half TdotL = dot(T, L);
                half TdotV = dot(T, V);

                half sinTL = sqrt(1 - TdotL * TdotL);
                half sinTV = sqrt(1 - TdotV * TdotV);

                half3 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;

                half3 diffuse = _Kd * sinTL;
                half3 specular = _Ks * pow(max(0.0, TdotL * TdotV + sinTL * sinTV), _SpecularExponent);
                
                half4 finalColor = half4(diffuse * mainColor + specular, 0);

                finalColor.rgb *= SAMPLE_TEXTURE2D(_HairShiftTex, sampler_HairShiftTex, IN.uv).rgb;
                finalColor.a = SAMPLE_TEXTURE2D(_HairAlphaTex, sampler_HairAlphaTex, IN.uv).r;

                return finalColor;
            }
            ENDHLSL
        }
    }
}
