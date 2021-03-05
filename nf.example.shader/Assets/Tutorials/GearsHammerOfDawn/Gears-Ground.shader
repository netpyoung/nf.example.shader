Shader "Gears-Ground"
{
    // ref:
    // - https://lexdev.net/tutorials/case_studies/gears_hammerofdawn.html
    // - https://github.com/LexdevTutorials/GearsHammerOfDawn

    // 땅 메쉬를 잘게 쪼게놓는다.

    Properties
    {
        [Toggle]
        _Debug("Debug", Float) = 0

        [NoScaleOffset] _NoiseTex("Noise Texture", 2D) = "white" {}

        //0 = start of the sequence (slightly cracked floor), 1 = end of sequence (everything gone crazy)
        _Sequence("Sequence", Range(0,1)) = 0.0
        _Exp("Shape Exponent", Range(1.0,10.0)) = 5.0
        _Rot("Rotation Multiplier", Range(1.0,100.0)) = 50.0
        _Height("Height Multiplier", Range(0.1,1.0)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma shader_feature_local _DEBUG_OFF _DEBUG_ON

            TEXTURE2D(_NoiseTex);     SAMPLER(sampler_NoiseTex);

            CBUFFER_START(UnityPerMaterial)
                half _Sequence;
                half _Exp;
                half _Rot;
                half _Height;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normal       : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 N            : TEXCOORD0;
#if _DEBUG_ON
                float3 color        : TEXCOORD1;
#endif
            };

            void Rotate(inout half4 vertex, inout half3 normal, half3 center, half3 around, half angle)
            {
                // 이동행렬
                // | 1 0 0 x |
                // | 0 1 0 y |
                // | 0 0 1 z |
                // | 0 0 0 1 |
                half4x4 translation = half4x4(
                    1, 0, 0, center.x,
                    0, 1, 0, -center.y,
                    0, 0, 1, -center.z,
                    0, 0, 0, 1
                );

                half4x4 translationT = half4x4(
                    1, 0, 0, -center.x,
                    0, 1, 0, center.y,
                    0, 0, 1, center.z,
                    0, 0, 0, 1
                );

                //Calculate some values that are used often
                around.x = -around.x;
                around = normalize(around);

                half s = sin(angle);
                half c = cos(angle);
                half ic = 1.0 - c;

                // 회전행렬
                // X 축
                // |    1    0    0  0 |
                // |    0  cos -sin  0 |
                // |    0  sin  cos  0 |
                // |    0    0    0  1 |
                // Y 축
                // |  cos    0  sin  0 |
                // |    0    1    0  0 |
                // | -sin    0  cos  0 |
                // |    0    0    0  1 |
                // Z 축
                // |  cos  -sin    0  0 |
                // |  sin   cos    0  0 |
                // |    0     0    1  0 |
                // |    0     0    0  1 |
                half4x4 rotation = half4x4(
                    ic * around.x * around.x + c           , ic * around.x * around.y - s * around.z, ic * around.z * around.x + s * around.y, 0,
                    ic * around.x * around.y + s * around.z, ic * around.y * around.y + c           , ic * around.y * around.z - s * around.x, 0,
                    ic * around.z * around.x - s * around.y, ic * around.y * around.z + s * around.x, ic * around.z * around.z + c           , 0,
                    0                                      , 0                                      , 0                                      , 1
                );

                //Rotate the vertex and its normal
                vertex = mul(translationT, mul(rotation, mul(translation, vertex)));
                normal = mul(translationT, mul(rotation, mul(translation, float4(normal, 0.0f)))).xyz;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;

                // 노이즈 빈도를 높이기위헤 uv값에 2를 곱했다.
                half noiseTexVal = SAMPLE_TEXTURE2D_LOD(_NoiseTex, sampler_NoiseTex, IN.uv * 2, 0);

                // 중심점 이동 [0, 1] => [-0.5, 0.5].
                half2 uvDir = IN.uv - 0.5f;

                half scaledSequence = _Sequence * 1.52 - 0.02;
                half sequenceVal = pow(1 - (noiseTexVal + 1) * length(uvDir), _Exp) * scaledSequence;

                half3 center = half3(2.0f * uvDir, 0);
                half3 around = cross(half3(uvDir, 0), half3(noiseTexVal * 0.1f, 0, 1));
                half angle = sequenceVal * _Rot;

                Rotate(IN.positionOS, IN.normal, center, around, angle);

                IN.positionOS.z += sin(sequenceVal * 2) * (noiseTexVal + 1) * _Height;
                IN.positionOS.xy -= normalize(half2(IN.uv.x, 1 - IN.uv.y) - 0.5) * sequenceVal * noiseTexVal;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.N = TransformObjectToWorldDir(IN.normal);

#if _DEBUG_ON
                OUT.color = noiseTexVal;
                // OUT.color = half3(IN.uv, 0);
                // OUT.color = IN.positionOS.xyz;
                // OUT.color = sequenceVal;
#endif
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // basic lighting
                Light light = GetMainLight();
                half3 L = light.direction;
                half3 N = normalize(IN.N);
                half NdotL = dot(N, L);

#if _DEBUG_ON
                return half4(NdotL * IN.color, 1);
#else
                return half4(NdotL, NdotL, NdotL, 1);
#endif
            }
            ENDHLSL
        }
    }
}
