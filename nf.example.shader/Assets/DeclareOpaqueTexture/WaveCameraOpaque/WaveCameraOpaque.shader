Shader "WaveCameraOpaque"
{
    // ref: [LWRP(URP) 에서 굴절(Refraction) 만들기](https://chulin28ho.tistory.com/555)
    // Queue / RenderType 확인.
    // PipelineAsset> General> Opaque Texture> 체크.

    Properties
    {
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent" // ***
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite Off

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl" // SampleSceneColor

            //TEXTURE2D(_CameraOpaqueTexture);
            //SAMPLER(sampler_CameraOpaqueTexture);
            //CBUFFER_START(UnityPerMaterial)
            //    float4 _CameraOpaqueTexture_ST;
            //CBUFFER_END

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
                float3 N                : TEXCOORD1;
                float3 positionWS       : TEXCOORD2;
                float4 positionNDC      : TEXCOORD3;

            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                ZERO_INITIALIZE(Varyings, OUT);

                VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = vertexInputs.positionCS;
                OUT.uv = IN.uv;
                OUT.N = TransformObjectToWorldNormal(IN.normalOS);
                OUT.positionWS = vertexInputs.positionWS;
                OUT.positionNDC = vertexInputs.positionNDC;
                return OUT;
            }

            inline float Unity_SimpleNoise_RandomValue_float(float2 uv)
            {
                // https://chulin28ho.tistory.com/555
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            }

            void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
            {
                // https://docs.unity3d.com/Packages/com.unity.shadergraph@6.9/manual/Fresnel-Effect-Node.html
                Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
            }

            // -----
            // https://docs.unity3d.com/Packages/com.unity.shadergraph@7.1/manual/Simple-Noise-Node.html
            inline float unity_noise_randomValue(float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            }

            inline float unity_noise_interpolate(float a, float b, float t)
            {
                return (1.0 - t) * a + (t * b);
            }

            inline float unity_valueNoise(float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);

                uv = abs(frac(uv) - 0.5);
                float2 c0 = i + float2(0.0, 0.0);
                float2 c1 = i + float2(1.0, 0.0);
                float2 c2 = i + float2(0.0, 1.0);
                float2 c3 = i + float2(1.0, 1.0);
                float r0 = unity_noise_randomValue(c0);
                float r1 = unity_noise_randomValue(c1);
                float r2 = unity_noise_randomValue(c2);
                float r3 = unity_noise_randomValue(c3);

                float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
                float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
                float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
                return t;
            }

            void Unity_SimpleNoise_float(float2 UV, float Scale, out float Out)
            {
                float t = 0.0;

                float freq = pow(2.0, float(0));
                float amp = pow(0.5, float(3 - 0));
                t += unity_valueNoise(float2(UV.x * Scale / freq, UV.y * Scale / freq)) * amp;

                freq = pow(2.0, float(1));
                amp = pow(0.5, float(3 - 1));
                t += unity_valueNoise(float2(UV.x * Scale / freq, UV.y * Scale / freq)) * amp;

                freq = pow(2.0, float(2));
                amp = pow(0.5, float(3 - 2));
                t += unity_valueNoise(float2(UV.x * Scale / freq, UV.y * Scale / freq)) * amp;

                Out = t;
            }
            // -----

            half4 frag(Varyings IN) : SV_Target
            {
                half time = _Time.y;
            
                half2 screenUV = IN.positionNDC.xy / IN.positionNDC.w;

                half noise;
                Unity_SimpleNoise_float(screenUV + time * 0.2, 100, noise);
                noise *= 0.08;

                half3 N = normalize(IN.N);
                half3 V = TransformWorldToViewDir(IN.positionWS.xyz);

                half fresnelEffect;
                Unity_FresnelEffect_float(N, V, 0.27, fresnelEffect);
                fresnelEffect = 1 - fresnelEffect * 0.02;
                
                // SampleSceneColor - com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl
                half3 mainColor = SampleSceneColor(screenUV + noise * fresnelEffect);
                return half4(mainColor, 1);
            }
            ENDHLSL
        }
    }
}
