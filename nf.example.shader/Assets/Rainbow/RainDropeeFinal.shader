Shader "RainDropeeFinal"
{
    // ref: 
    // - https://deepspacebanana.github.io/blog/shader/art/unreal%20engine/Rainy-Surface-Shader-Part-1
    // - https://deepspacebanana.github.io/blog/shader/art/unreal%20engine/Rainy-Surface-Shader-Part-2

    // _DropletPatternPackTex
    // | r | droplet         | 
    // | g | streaks         | 
    // | b | streak gradient | 
    // | a | -               | 
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _NormalTex("Normal Map", 2D) = "" {}

        _DropletPatternPackTex("Pattern Map(Packed)", 2D) = "" {}
        _DropletNormalTex("Droplet Normal", 2D) = "" {}
        _DropletOffsetX("Droplet Offset X", Float) = 0.1
        _DropletOffsetY("Droplet Offset Y", Float) = 0.1
        _RainSpeed("Rain Speed", Range(0, 1)) = 1
        _EdgeWidth("Edge Width", Float) = 0.05
        _TimeOffset("Time Offset", Float) = 0.5

        _WaterColor("Water Color", Color) = (0.5, 0.7, 1, 1)
        _WaterBrightness("Water Brightness", Float) = 0.4

        _StreakTiling("Streak Tiling", Float) = 1
        _StreakLength("Streak Length", Float) = 1
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

            TEXTURE2D(_DropletPatternPackTex);
            SAMPLER(sampler_DropletPatternPackTex);
            TEXTURE2D(_DropletNormalTex);
            SAMPLER(sampler_DropletNormalTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NormalTex_ST;

                float4 _DropletPatternPackTex_ST;
                float4 _DropletNormalTex_ST;

                half _DropletOffsetX;
                half _DropletOffsetY;
                half _RainSpeed;
                half _EdgeWidth;
                half _TimeOffset;

                half4 _WaterColor;
                half _WaterBrightness;
                
                half _StreakTiling;
                half _StreakLength;
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

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                ExtractTBN(IN.normalOS, IN.tangent, OUT.T, OUT.B, OUT.N);

                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);

                return OUT;
            }

            half EdgeMask(half droplet, half edgeWidth)
            {
                // 내부에 작은 검은 마스크를 만들어 결과적으로 흰색 테두리 효과.

                // 0  0.05        0.95 1
                // |--|--------------|-|
                // 검        회        흰

                // smoothstep(min, max, x);
                // - [min, max]사이의 Hermite 보간

                // 0.04 ~ 0 | 0 ~ 0.05 ~ 0.9 | 0.9 ~ 0.95 // distance 0.05
                // 0        | 0 ~ 1    ~ 18  | 18  ~ 19   // divide   0.05
                // 0        | 0 ~ 1          | 1          // smoothstep
                half edgeMask = smoothstep(0, 1, distance(droplet, 0.05) / edgeWidth);

                // 1        | 1 ~ 0          | 0           // 1 - x
                return 1 - edgeMask;
            }

            half RippleFade(half dropletTime)
            {                
                // ripple: 잔물결
                // 시간에따른 Fade in / out 효과
                return abs(sin(dropletTime * PI));
            }

            half InterpolationTime(half time, half rainSpeed)
            {
                half interpolationTime = abs(sin(time * rainSpeed * PI));
                // clamp(x, a, b)
                // => max(a, min(b, x));
                // | x < a             | a
                // |             b < x | b
                // |     a < x < b     | x
                return clamp(interpolationTime, 0, 1);
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // _Time : https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html
                half time = _Time.y;
                
                half3 packedColor = SAMPLE_TEXTURE2D(_DropletPatternPackTex, sampler_DropletPatternPackTex, IN.uv).rgb;

                half dropletTime1 = time * _RainSpeed;
                // frac: 소수점이하 리턴.
                half emissive1 = (1 - frac(dropletTime1)); // 0.99 ~ 0
                half droplet1 = packedColor.r - emissive1;
                half edgeMask1 = EdgeMask(droplet1, _EdgeWidth);
                half rippleFade1 = RippleFade(dropletTime1);

                half2 dropletOffset = half2(_DropletOffsetX, _DropletOffsetY);
                half dropletTime2 = (time + _TimeOffset) * _RainSpeed;
                half emissive2 = (1 - frac(dropletTime2));
                half droplet2 = SAMPLE_TEXTURE2D(_DropletPatternPackTex, sampler_DropletPatternPackTex, IN.uv + dropletOffset).r - emissive2;
                half edgeMask2 = EdgeMask(droplet2, _EdgeWidth);
                half rippleFade2 = RippleFade(dropletTime2);
                
                half interpolationTime = InterpolationTime(time, _RainSpeed);

                half ripple1 = edgeMask1 * rippleFade1;
                half ripple2 = edgeMask2 * rippleFade2;
                half ripple = lerp(ripple1, ripple2, interpolationTime);

                half3 dropletTangentNormal1 = UnpackNormal(SAMPLE_TEXTURE2D(_DropletNormalTex, sampler_DropletNormalTex, IN.uv));
                half3 dropletTangentNormal2 = UnpackNormal(SAMPLE_TEXTURE2D(_DropletNormalTex, sampler_DropletNormalTex, IN.uv + dropletOffset));
                dropletTangentNormal1.xy *= -ripple1;
                dropletTangentNormal2.xy *= -ripple2;

                half3 dropletTangentNormal = lerp(dropletTangentNormal1, dropletTangentNormal2, interpolationTime);

            
                half zGradient = CombineTBN(half3(0, 0, 1), IN.T, IN.B, IN.N).y;
                zGradient *= 1.1;
                zGradient = clamp(zGradient, 0, 1);
                
                half3 positionWS = IN.positionWS;
                half3 gsPositionWS = half3(0, 0, 0);
                half3 x = (positionWS - gsPositionWS) / _StreakTiling;
                x.b /= _StreakLength;


                // steak G - mask
                half3 y = lerp(
                    SAMPLE_TEXTURE2D(_DropletPatternPackTex, sampler_DropletPatternPackTex, x.rg).g,
                    SAMPLE_TEXTURE2D(_DropletPatternPackTex, sampler_DropletPatternPackTex, x.bg).g,
                    abs(IN.N.x)
                );

                // steak normal
                half3 z = lerp(
                    UnpackNormal(SAMPLE_TEXTURE2D(_DropletNormalTex, sampler_DropletNormalTex, x.rg)),
                    UnpackNormal(SAMPLE_TEXTURE2D(_DropletNormalTex, sampler_DropletNormalTex, x.bg)),
                    abs(IN.N.x)
                );

                half3 x2 = (positionWS - gsPositionWS) / (2 * _StreakTiling);
                x2.y /= _StreakLength;
                x2.y += time * _RainSpeed;

                // steak B - panning
                half3 y2 = lerp(
                    SAMPLE_TEXTURE2D(_DropletPatternPackTex, sampler_DropletPatternPackTex, x2.rg).b,
                    SAMPLE_TEXTURE2D(_DropletPatternPackTex, sampler_DropletPatternPackTex, x2.bg).b,
                    abs(IN.N.x)
                );

                half steakMask = saturate((y.x - saturate(pow(y2.r, 8))) * 5);

                //return half4(zGradient, zGradient, zGradient, 1);
                //return half4(yy, yy, yy, 1);

                    
                half3 steakNormal = lerp(half3(0.5, 0.5, 1), z, steakMask);

                // BlendNomral
                // - com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl
                half3 mainTangentNormal = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, IN.uv));
                
                half3 blendedTangentNormal = BlendNormal(mainTangentNormal, lerp(dropletTangentNormal, steakNormal, 1-zGradient));
                half3 tangentNormal = lerp(mainTangentNormal, blendedTangentNormal, interpolationTime);

                half3 N = CombineTBN(tangentNormal, IN.T, IN.B, IN.N);

                Light light = GetMainLight();
                half3 L = normalize(light.direction);

                half NdotL = max(0.0, dot(N, L));

                half3 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;

                //half3 diffuse = ripple;
                half3 finalMask = lerp(y, ripple,  zGradient);
                half3 diffuse = (mainColor * _WaterColor * _WaterBrightness + finalMask / 5) * NdotL;

                return half4(diffuse, 1);
                //return half4(z, 1);
            }
            ENDHLSL

        }
    }
}
