Shader "example/02_texture"
{
    Properties
    {
        _MainTex("texture", 2D) = "white" {}
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
        
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float2 uv            : TEXCOORD0;
                float3 normalOS     : NORMAL;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float2 uv            : TEXCOORD0;

                float3 N            : TEXCOORD1;
                float3 V            : TEXCOORD2;
                float3 L            : TEXCOORD3;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                OUT.N = TransformObjectToWorldNormal(IN.normalOS);
                OUT.V = GetWorldSpaceViewDir(TransformObjectToWorld(IN.positionOS.xyz));

                Light light = GetMainLight();
                OUT.L = light.direction;

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 N = normalize(IN.N);
                half3 V = normalize(IN.V);

                float3 VrN = reflect(-V, N);
                float lod = 1;
                float3 probe0 = DecodeHDREnvironment(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, VrN, lod), unity_SpecCube0_HDR);

                return float4(probe0, 1);
            }
            ENDHLSL
        }
    }
}
