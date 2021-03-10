Shader "Gears-Ground"
{
    // ref:
    // - https://lexdev.net/tutorials/case_studies/gears_hammerofdawn.html
    // - https://github.com/LexdevTutorials/GearsHammerOfDawn

    // 땅 메쉬를 잘게 쪼게놓는다.

    Properties
    {
        [Toggle]
        _DebugColor("Debug Color", Float) = 0
        [Toggle]
        _DebugRotate("Debug Rotate", Float) = 0

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

            #pragma shader_feature_local _DEBUGCOLOR_OFF _DEBUGCOLOR_ON
            #pragma shader_feature_local _DEBUGROTATE_OFF _DEBUGROTATE_ON
            

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
#if _DEBUGCOLOR_ON
                float3 color        : TEXCOORD1;
#endif
            };

            void Rotate(inout half4 vertex, inout half3 normal, half3 center, half3 n, half angle)
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
                n.x = -n.x;
                n = normalize(n);

                // n축 angle회전 행렬.
                // ref: https://www.3dgep.com/3d-math-primer-for-game-programmers-matrices/#Rotation_about_an_arbitrary_axis
                half s = sin(angle);
                half c = cos(angle);
                half ic = 1.0 - c;
                half4x4 rotation = half4x4(
                    ic * n.x * n.x + c      , ic * n.x * n.y - s * n.z, ic * n.z * n.x + s * n.y, 0,
                    ic * n.x * n.y + s * n.z, ic * n.y * n.y + c      , ic * n.y * n.z - s * n.x, 0,
                    ic * n.z * n.x - s * n.y, ic * n.y * n.z + s * n.x, ic * n.z * n.z + c      , 0,
                    0                       , 0                       , 0                       , 1
                );

                //Rotate the vertex and its normal
                vertex = mul(translationT, mul(rotation, mul(translation, vertex)));
                normal = mul(translationT, mul(rotation, mul(translation, half4(normal, 0.0f)))).xyz;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                ZERO_INITIALIZE(Varyings, OUT);

                // 노이즈 빈도를 높이기위헤 uv값에 2를 곱했다.
                half noiseTexVal = SAMPLE_TEXTURE2D_LOD(_NoiseTex, sampler_NoiseTex, IN.uv * 2, 0);

                // 중심점 이동 [0, 1] => [-0.5, 0.5].
                half2 uvDir = IN.uv - 0.5f;

                half sequenceScale = _Sequence * 1.52 - 0.02; // 하드코딩으로(* 1.52 - 0.02) 범위조정.

                // length(uvDir)을 이용하여, 중심에 가까울 수록 흰색(1), 멀어질수록 검정색(0)
                half sequenceVal = pow(1 - (noiseTexVal + 1) * length(uvDir), _Exp) * sequenceScale;

#if _DEBUGROTATE_OFF
                half3 center = half3(2.0f * uvDir, 0);                                  // [-0.5, 0.5] => [-1, 1]
                half3 around = cross(half3(uvDir, 0), half3(noiseTexVal * 0.1, 0, 1));
                half angle = sequenceVal * _Rot;
                Rotate(IN.positionOS, IN.normal, center, around, angle);
#endif

                // 높이: 노이즈 색깔별(noiseTexVal + 1)로 띄우고, PI주기인 sin을 이용하여 굴곡형성.
                IN.positionOS.z += (noiseTexVal + 1) * _Height * sin(sequenceVal * 2);
                // 넓이: uv의 y를 뒤짚어서 양옆으로 넓히기.
                IN.positionOS.xy -= normalize(half2(IN.uv.x, 1 - IN.uv.y) - 0.5) * sequenceVal * noiseTexVal;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.N = TransformObjectToWorldDir(IN.normal);

#if _DEBUGCOLOR_ON
                // OUT.color = noiseTexVal;
                // OUT.color = half3(uvDir, 0);
                // OUT.color = length(uvDir);
                OUT.color = sequenceVal;
                // OUT.color = half3(IN.uv, 0);
                // OUT.color = IN.positionOS.xyz;
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

#if _DEBUGCOLOR_ON
                return half4(NdotL * IN.color, 1);
#else
                return half4(NdotL, NdotL, NdotL, 1);
#endif
            }
            ENDHLSL
        }
    }
}
