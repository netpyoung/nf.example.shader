Shader "Gears-Beam"
{
    // ref:
    // - https://lexdev.net/tutorials/case_studies/gears_hammerofdawn.html
    // - https://github.com/LexdevTutorials/GearsHammerOfDawn

    Properties
    {
        _NoiseTex("Noise Texture", 2D) = "white" {}

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
                float2 uv           : TEXCOORD0;
                float3 N            : TEXCOORD1;
                float4 positionNDC  : TEXCOORD2;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;

                VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionHCS = vertexInputs.positionCS;
                OUT.uv = IN.uv;
                OUT.N = TransformObjectToWorldDir(IN.normal);
                OUT.positionNDC = vertexInputs.positionNDC;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                Light light = GetMainLight();
                half3 L = light.direction;
                half3 N = normalize(IN.N);

                half NdotL = max(0, dot(N, L));

                half lightIntensity = NdotL * 0.5 + 0.5;
                return 1;
            }
            ENDHLSL
        }
    }
}
