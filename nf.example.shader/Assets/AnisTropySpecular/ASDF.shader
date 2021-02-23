Shader "Unlit/ASDF"
{
    // 에이지어(dasoong15)
    //   - https://blog.naver.com/dasoong15/221984590387
    //   - https://www.youtube.com/watch?v=SZmKGUo0oIg

    // https://www.slideshare.net/dongminpark71/ndc19-pbr-143928930 - 92page

    // http://wiki.unity3d.com/index.php?title=Anisotropic_Highlight_Shader&oldid=14318
    // 이방성(비등방성) 스펙큘러: 방향에 따라 물체의 물리적 성질이 다른 것.
    
    // https://www.pythonstuff.org/glsl/example_7_anisotropic_highlights.html

    // _SpecularTex
    // | R | Specular         | brightness                                                 |
    // | G | Gloss            | how sharp(full green) or wide(no green)                    |
    // | B | Anisotropic Mask |  blend. Full blue = full anisotropic, no blue = full blinn.|

    // _AnisoTex (Normal)
    // Anisotropic Direction : Direction of the surface highlight.Follows the same directional values as a tangent space normal map.

    // Anisotropic Offset : Can be used to push the highlight towards or away from the centre point.

    // TODO -
    // 헤어모델
    //   - Kajya-Kay 모델                -
    //     - 짧은머리는 괜춘. 빛의 산란효과는 별로
    //   - Steve Marschner 모델                      - SIGGRAPH 2003
    //     - 빛의 산란효과 개선(반사/내부산란/투과)
    //   - Scheuermann - Hair Rendering and Shading - GDC 2004
    // 
    // https://www.slideshare.net/leemwymw/2012agnis-philosophy-29748631
    // https://www.fxguide.com/fxfeatured/pixars-renderman-marschner-hair/
    // https://gamedevforever.com/113

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Normal]_NormalTex("Normal Map", 2D) = "" {}
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

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NormalTex_ST;
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
                float4 positionHCS      : SV_POSITION;
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
                Varyings OUT = (Varyings)0;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                ExtractTBN(IN.normalOS, IN.tangent, OUT.T, OUT.B, OUT.N);

                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            half StrandSpecular(half3 T, half3 V, half3 L, half exponent)
            {
                half3 H = normalize(L + V);
                half TdotH = dot(T, H);

                // sin(T, H) == sqrt(1 - TdotH * TdotH)
                half sinTH = sqrt(1.0 - TdotH * TdotH);
                half dirAtten = smoothstep(-1.0, 0.0, TdotH);

                return dirAtten * pow(sinTH, exponent);
            }


            // com.unity.render-pipelines.core/ShaderLibrary/BSDF.hlsl
            // real3 ShiftTangent(real3 T, real3 N, real shift)
            // real3 D_KajiyaKay(real3 T, real3 H, real specularExponent)

            half4 frag(Varyings  IN) : SV_Target
            {
                half3 mainNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, IN.uv));

                Light light = GetMainLight();
                
                half3 N = CombineTBN(mainNormalTS, IN.T, IN.B, IN.N);
                half3 L = normalize(light.direction);
                half3 V = TransformWorldToViewDir(IN.positionWS);
                half3 H = normalize(L + V);

                half NdotL = max(0.0, dot(N, L));

                half3 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;

                half3 diffuse = (mainColor * NdotL);
                //half specular = StrandSpecular(IN.T, IN.B, N, V, L, 0.001, 1);
                half3 specular = D_KajiyaKay(ShiftTangent(IN.T, N, 3), H, 2);
                return half4(diffuse + specular, 1);
                //half3 L = 0;
                //half3 lightColor = 0;
                //half3 V = 0;
                //half3 N = (0.5, 0.5, 1);
                //half3 anisoDir = half(0, -1000, 0);
                //half anisoOffset = 1;
                //half anisoMask = 1;
                //half gloss = 1;
                //half specular= 1;
                //half atten = 1;
                //half cutoff= 0;
                //half alpha = 1;

                //half3 H = normalize(L + V);
                //half NdotL = saturate(dot(N, L));
                //half NdotH = saturate(dot(N, H));

                //half HdotA = dot(normalize(N + anisoDir), H);
                //half aniso = max(0, sin(radians((HdotA + anisoOffset) * 180)));
                //
                //half spec = saturate(pow(lerp(NdotH, aniso, anisoMask), gloss * 128) * specular);

                //half3 mainColor = (lightColor * spec) * (atten * 2);
                //half4 finalColor = half4(mainColor, Alpha - Cutoff);
            }
            ENDHLSL
        }
    }
}
