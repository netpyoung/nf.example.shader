Shader "FakeThinFilm"
{
    // ref: https://cedil.cesa.or.jp/cedil_sessions/view/1892

    Properties
    {
        _MainTex("texture", 2D) = "white" {}
        _VMask("_VMask", Float) = 1
        _Thickness("_Thickness", Range(0, 2)) = 0.15
        _IOR("_IOR", Range(0, 1)) = 0.50 // IOR (Index of Refraction)
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
            Name "FAKE_THIN_FLIM"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _ IS_UNCHARTED2

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            
            float _VMask;
            float _Thickness;
            float _IOR;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float2 uv            : TEXCOORD0;
                float3 normal        : NORMAL;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float2 uv            : TEXCOORD0;
                float3 N            : TEXCOORD1;
                float3 positionWS    : TEXCOORD2;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.N = TransformObjectToWorldNormal(IN.normal);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);

                return OUT;
            }

            float3 FakeThinFilm(float3 view_dir, float3 normalWS, float vmask, float thickness, float IOR)
            {
                float cos0 = abs(dot(view_dir, normalWS));

                cos0 *= vmask;
                float tr = cos0 * thickness - IOR;
                float3 n_color = (cos((tr * 35.0) * float3(0.71, 0.87, 1.0)) * -0.5) + 0.5;
                n_color = lerp(n_color, float3(0.5, 0.5, 0.5), tr);
                n_color *= n_color * 2.0f;
                return n_color;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                half3 V = GetWorldSpaceNormalizeViewDir(IN.positionWS.xyz);
                half3 N = normalize(IN.N);

                half3 color = FakeThinFilm(V, N, _VMask, _Thickness, _IOR);
                return half4(mainTex * color, 1);
            }
            ENDHLSL
        }
    }
}
