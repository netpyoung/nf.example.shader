Shader "srp/PostProcessScan"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _WaveDistance("Distance from player", Range(0, 20)) = 10
        _WaveTrail("Length of the trail", Range(0,5)) = 1
        _WaveColor("Color", Color) = (1,0,0,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
        }

        Cull Back
        ZWrite Off
        ZTest Off

        HLSLINCLUDE
        #pragma target 3.5
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
        #pragma vertex Vert
        #pragma fragment frag
        ENDHLSL

        Pass // 0
        {
            NAME "POSTPROCESS_SCAN"

            HLSLPROGRAM
            half _WaveDistance;
            half _WaveTrail;
            half4 _WaveColor;

            half4 frag(Varyings IN) : SV_Target
            {
                half4 blitTex = SAMPLE_TEXTURE2D(_BlitTexture, sampler_PointClamp, IN.texcoord);
                half2 screenUV = IN.texcoord;
                half sceneDepth = SampleSceneDepth(screenUV);
                // return sceneDepth;
                half eyeDepth = LinearEyeDepth(SampleSceneDepth(screenUV), _ZBufferParams);
                if (eyeDepth >= _ProjectionParams.z)
                {
                    return blitTex;
                }

                half waveFront = step(eyeDepth, _WaveDistance);
                half waveTrail = smoothstep(_WaveDistance - _WaveTrail, _WaveDistance, eyeDepth);
                half wave = waveFront * waveTrail;
                half4 finalColor = lerp(blitTex, _WaveColor, wave);
                return finalColor;
            }
            ENDHLSL
        }
    }
}


