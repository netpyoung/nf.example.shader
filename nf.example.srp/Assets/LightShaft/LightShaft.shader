Shader "srp/LightShaft"
{
    HLSLINCLUDE
    ENDHLSL

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [IntRange] _MaxIteration("_MaxIteration", Range(0, 64)) = 64
        _MinDistance("_MinDistance", Range(0, 20)) = 0.4
        _MaxDistance("_MaxDistance", Range(0, 20)) = 12
    }

    SubShader
    {
        Pass // 0
        {
            NAME "PASS_LIGHTSHAFT_GRADIENTFOG"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #pragma vertex vert
            #pragma fragment frag
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            float3 _CameraPositionWS;
            float4x4 _Matrix_CameraFrustum;

            int _MaxIteration;
            half _MinDistance;
            half _MaxDistance;
            half _DepthOutsideDecreaseValue;
            half _DepthOutsideDecreaseSpeed;

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS        : SV_POSITION;
                float2 uv                : TEXCOORD0;
                float3 frustumPositionWS : TEXCOORD1;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;

                int frustumIndex       = (int)(IN.uv.x + 2 * IN.uv.y);
                half3 frustumPositionWS = _Matrix_CameraFrustum[frustumIndex].xyz;

                OUT.frustumPositionWS = frustumPositionWS;
                return OUT;
            }

            float Random(float2 uv, int seed)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233)) + seed) * 43758.5453);
            }

            half SimpleRaymarching(in half3 rayStartPositionWS, in half3 rayDirWS, in half rayLimit)
            {
                half step = _MaxDistance / _MaxIteration;
                half stepDistance = _MinDistance + (step * Random(rayDirWS.xy, _Time.y * 100));
                // stepDistance = _MinDistance;

                half alpha = 0;
                for (int i = 0; i < _MaxIteration; ++i)
                {
                    if (stepDistance > _MaxDistance || stepDistance > rayLimit)
                    {
                        break;
                    }

                    half3 nextPositionWS = rayStartPositionWS + (rayDirWS * stepDistance);
                    half4 shadowCoord = TransformWorldToShadowCoord(nextPositionWS);
                    half shadow = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord);
                    if (shadow >= 1)
                    {
                        alpha += step * 0.2;
                    }
                    stepDistance += step;
                }

                return saturate(alpha);
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half  sceneRawDepth = SampleSceneDepth(IN.uv);
                half  scene01Depth  = Linear01Depth(sceneRawDepth, _ZBufferParams);
                half depth = scene01Depth;
                half depthDecreaseAmount = _DepthOutsideDecreaseValue * 0.01;
                if (depth > depthDecreaseAmount)
                {
                    depth = saturate(depth - (depth - depthDecreaseAmount) * _DepthOutsideDecreaseSpeed);
                }
                depth *= length(IN.frustumPositionWS);

                half3 rayStartPositionWS = _CameraPositionWS;
                // frustumPositionWS이 각 꼭지점을 가르키더라도, normalize를 하면 방향이 분산되는 효과가 있다.
                half3 rayDirWS = normalize(IN.frustumPositionWS);
                return SimpleRaymarching(rayStartPositionWS, rayDirWS, depth);
            }

            ENDHLSL
        }

        Pass // 1
        {
            NAME "PASS_LIGHTSHAFT_COMBINE"

            Cull Off
            ZWrite Off
            ZTest Always

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag

            TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
            TEXTURE2D(_LightShaftMaskTex);  SAMPLER(sampler_LightShaftMaskTex);
            float _Intensity;

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
                half lightShaftMaskTex = SAMPLE_TEXTURE2D(_LightShaftMaskTex, sampler_LightShaftMaskTex, IN.uv).r;
                half3 color = lerp(mainTex, _Intensity * _MainLightColor.rgb, lightShaftMaskTex);
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}
