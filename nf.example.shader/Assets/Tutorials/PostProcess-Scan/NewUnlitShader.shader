Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        [HideInInspector] _MainTex("Texture", 2D) = "white" {}

        _Color("Color", Color) = (1, 1, 1, 1)
        _WaveDistance("Distance from player", Range(0, 20)) = 10
        _WaveTrail("Length of the trail", Range(0,5)) = 1
        _WaveColor("Color", Color) = (1,0,0,1)
    }

        SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            //"Queue" = "Transparent"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            
            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

            half _WaveDistance;
            half _WaveTrail;
            half4 _WaveColor;

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float4 positionNDC  : TEXCOORD1;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                ZERO_INITIALIZE(Varyings, OUT);

                VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);

                OUT.positionCS = vertexInputs.positionCS;
                OUT.positionNDC = vertexInputs.positionNDC;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                
                half2 screenUV = IN.positionNDC.xy / IN.positionNDC.w;

                half depth = LinearEyeDepth(SampleSceneDepth(screenUV), _ZBufferParams);
                if (depth >= _ProjectionParams.z)
                {
                    return mainTex;
                }

                half waveFront = step(depth, _WaveDistance);
                half waveTrail = smoothstep(_WaveDistance - _WaveTrail, _WaveDistance, depth);
                half wave = waveFront * waveTrail;
                half4 finalColor = lerp(mainTex, _WaveColor, wave);
                return finalColor;
            }
            ENDHLSL
        }
    }
}


