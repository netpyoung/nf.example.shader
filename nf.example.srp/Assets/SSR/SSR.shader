Shader "srp/SSR"
{
    Properties
    {
        [HideInInspector] _MainTex("UI Texture", 2D) = "white" {}
        [IntRange] _MaxIteration("_MaxIteration", Range(0, 64)) = 64
    }

    SubShader
    {
        Pass // 0
        {
            NAME "PASS_SSR_CALCUATE_REFLECTION"

            Cull Back
            ZWrite Off
            ZTest Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
    
            float4 _MainTex_TexelSize;

            int _MaxIteration;
            half _MinDistance;
            half _MaxDistance;
            half _MaxThickness;

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 cameraRay    : TEXCOORD1;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                
                float4 cameraRay = float4(IN.uv * 2 - 1, 1, 1);
                cameraRay = mul(unity_CameraInvProjection, cameraRay);
                OUT.cameraRay = cameraRay.xyz / cameraRay.w;

                return OUT;
            }

            float ComputeDepth(float4 positionCS)
            {
#if defined(SHADER_TARGET_GLSL) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
                return (positionCS.z / positionCS.w) * 0.5 + 0.5;
#else
                return (positionCS.z / positionCS.w);
#endif
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                // 반사레이 시작점
                half  sceneRawDepth = SampleSceneDepth(IN.uv);
                half  scene01Depth = LinearEyeDepth(sceneRawDepth, _ZBufferParams);
                half3 reflectRayStartPositionVS = IN.cameraRay * scene01Depth;

                // 입사벡터
                half3 incidentVecVS = normalize(reflectRayStartPositionVS);

                // 반사레이벡터
                half3 normalVS = TransformWorldToView(SampleSceneNormals(IN.uv));
                half3 reflectRayDirVS = normalize(reflect(incidentVecVS, normalVS));

                // 레이 처리
                half step = _MaxDistance / _MaxIteration;
                half stepDistance = _MinDistance + step;
                half availableThickness = _MaxThickness / _MaxIteration;
                int iteratorCount = min(64, _MaxIteration);
                half4 reflectionColor = 0;

                UNITY_LOOP
                for (int i = 0; i < iteratorCount; ++i)
                {
                    // 반사레이 도착점 
                    half3 reflectRayEndPositionVS = reflectRayStartPositionVS + (reflectRayDirVS * stepDistance);
                    float4 reflectRayEndPositionCS = TransformWViewToHClip(reflectRayEndPositionVS);
                    float2 reflectRayEndUV = (reflectRayEndPositionCS.xy / reflectRayEndPositionCS.w) * 0.5 + 0.5;
                    //return half4(reflectRayEndUV, 0, 1);

                    bool isValidUV = max(abs(reflectRayEndUV.x - 0.5), abs(reflectRayEndUV.y - 0.5)) <= 0.5;
                    return isValidUV;
                    if (!isValidUV)
                    {
                        break;
                    }

                    half reflectRayEndDepth = ComputeDepth(reflectRayEndPositionCS);
                    half sceneReflectRayEndDepth = SampleSceneDepth(reflectRayEndUV);
                    half depthDiff = reflectRayEndDepth - sceneReflectRayEndDepth;
                    if (0 < depthDiff && depthDiff < availableThickness)
                    {
                        // 반사색
                        reflectionColor.rgb = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, reflectRayEndUV).rgb;
                        reflectionColor.a = 0.5;
                        break;
                    }

                    stepDistance += step;
                }
                return reflectionColor;
            }
            ENDHLSL
        }

        Pass // 1
        {
            NAME "PASS_SSR_COMBINE"

            Cull Off
            ZWrite Off
            ZTest Off

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_SsrTex);     SAMPLER(sampler_SsrTex);

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
                half4 ssrTex = SAMPLE_TEXTURE2D(_SsrTex, sampler_SsrTex, IN.uv);
                half3 result = lerp(mainTex, ssrTex.rgb, ssrTex.a);
                return half4(result, 1);
            }
            ENDHLSL
        }
    }
}
