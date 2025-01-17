﻿Shader "RainDropeeFinal"
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
        _RainStreakNormalTex("Rain Streak Normal", 2D) = "" {}
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
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
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
            TEXTURE2D(_RainStreakNormalTex);
            SAMPLER(sampler_RainStreakNormalTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NormalTex_ST;

                float4 _DropletPatternPackTex_ST;
                float4 _DropletNormalTex_ST;
                float4 _RainStreakNormalTex_ST;

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

            inline half EdgeMask(half droplet, half edgeWidth)
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
                // 1        | 1 ~ 0          | 0           // 1 - x
                return 1 - smoothstep(0, 1, distance(droplet, 0.05) / edgeWidth);
            }

            inline half RippleFade(half dropletTime)
            {
                // ripple: 잔물결
                // 시간에따른 Fade in / out 효과
                // sin PI값을 사용.
                return abs(sin(dropletTime * PI));
            }

            inline half InterpolationTime(half time, half rainSpeed)
            {
                //half interpolationTime = abs(sin(time * rainSpeed * PI));
                //// clamp(x, a, b)
                //// => max(a, min(b, x));
                //// | x < a             | a
                //// |             b < x | b
                //// |     a < x < b     | x
                //return clamp(interpolationTime, 0, 1);
                return abs(sin(time * rainSpeed * PI));
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                // _Time : https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html
                half time = _Time.y;

                // streak A - droplet
                half dropletTime1 = time * _RainSpeed;
                half emissive1 = (1 - frac(dropletTime1));
                half droplet1 = SAMPLE_TEXTURE2D(_DropletPatternPackTex, sampler_DropletPatternPackTex, IN.uv).r - emissive1;
                half edgeMask1 = EdgeMask(droplet1, _EdgeWidth);
                half rippleFade1 = RippleFade(dropletTime1);

                half2 dropletOffset = half2(_DropletOffsetX, _DropletOffsetY);
                half dropletTime2 = time * _RainSpeed + _TimeOffset;
                half emissive2 = (1 - frac(dropletTime2));
                half droplet2 = SAMPLE_TEXTURE2D(_DropletPatternPackTex, sampler_DropletPatternPackTex, IN.uv + dropletOffset).r - emissive2;
                half edgeMask2 = EdgeMask(droplet2, _EdgeWidth);
                half rippleFade2 = RippleFade(dropletTime2);

                half interpolationTime = InterpolationTime(time, _RainSpeed);

                half rippleMask1 = edgeMask1 * rippleFade1;
                half rippleMask2 = edgeMask2 * rippleFade2;
                half rippleMask = lerp(rippleMask1, rippleMask2, interpolationTime);

                half3 dropletNormalTS1 = UnpackNormal(SAMPLE_TEXTURE2D(_DropletNormalTex, sampler_DropletNormalTex, IN.uv));
                half3 dropletNormalTS2 = UnpackNormal(SAMPLE_TEXTURE2D(_DropletNormalTex, sampler_DropletNormalTex, IN.uv + dropletOffset));
                half3 dropletNormalTS = lerp(dropletNormalTS1, dropletNormalTS2, interpolationTime);


                half vertexNormalMaskAlongXAxis = abs(normalize(IN.N).x);

                // streak G - mask
                half3 positionWS = IN.positionWS;
                half3 gsPositionWS = half3(0, 0, 0);
                half3 streakGMaskUVs = (positionWS - gsPositionWS) / (2 * _StreakTiling);
                streakGMaskUVs.y /= _StreakLength;
                half streakGMask = lerp(
                    SAMPLE_TEXTURE2D(_DropletPatternPackTex, sampler_DropletPatternPackTex, streakGMaskUVs.rg).g,
                    SAMPLE_TEXTURE2D(_DropletPatternPackTex, sampler_DropletPatternPackTex, streakGMaskUVs.bg).g,
                    vertexNormalMaskAlongXAxis
                );
                // return half4(streakGMask, streakGMask, streakGMask, 1); // sample

                // streak B - panning
                half3 streakBPanningUVs = (positionWS - gsPositionWS) / (2 * _StreakTiling);
                streakBPanningUVs.y /= _StreakLength;
                streakBPanningUVs.y += (time * _RainSpeed);
                half streakBPanning = lerp(
                    SAMPLE_TEXTURE2D(_DropletPatternPackTex, sampler_DropletPatternPackTex, streakBPanningUVs.rg).b,
                    SAMPLE_TEXTURE2D(_DropletPatternPackTex, sampler_DropletPatternPackTex, streakBPanningUVs.bg).b,
                    vertexNormalMaskAlongXAxis
                );
                // return half4(streakBPanning, streakBPanning, streakBPanning, 1); // sample

                half streakMask = saturate((streakGMask - saturate(pow(streakBPanning, 8))) * 5);
                // return half4(streakMask, streakMask, streakMask, 1); // sample

                half3 streakNormal = lerp(
                    UnpackNormal(SAMPLE_TEXTURE2D(_RainStreakNormalTex, sampler_RainStreakNormalTex, streakBPanningUVs.rg)),
                    UnpackNormal(SAMPLE_TEXTURE2D(_RainStreakNormalTex, sampler_RainStreakNormalTex, streakBPanningUVs.bg)),
                    vertexNormalMaskAlongXAxis
                );
                // return half4(streakNormal, 1); // sample

                streakNormal = lerp(half3(0.5, 0.5, 1), streakNormal, streakMask);
                // return half4(streakNormal, 1); // sample

                half yGradient = CombineTBN(half3(0, 0, 1), IN.T, IN.B, IN.N).y;
                yGradient *= 1.1;
                yGradient = clamp(yGradient, 0, 1);
                // return half4(yGradient, yGradient, yGradient, 1); // sample

                // BlendNomral
                // - com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl
                half3 mainNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, IN.uv));
                half3 blendedNormalTS = BlendNormal(mainNormalTS, lerp(dropletNormalTS, streakNormal, yGradient));
                half3 finalNormalTS = lerp(mainNormalTS, blendedNormalTS, rippleMask);

                Light light = GetMainLight();
                half3 N = CombineTBN(finalNormalTS, IN.T, IN.B, IN.N);
                half3 L = normalize(light.direction);

                half NdotL = max(0.0, dot(N, L));

                half3 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;

                half finalMask = lerp(streakMask, rippleMask, yGradient);

                // return half4(finalMask, finalMask, finalMask, 1);

                half3 diffuse = (mainColor * _WaterColor.rgb * _WaterBrightness + finalMask * 0.5) * NdotL;

                return half4(diffuse, 1); // sample
            }
            ENDHLSL
        }
    }
}