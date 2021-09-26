Shader "example/VertexMultipleLight"
{
    Properties
    {
        _DiffuseTex("_DiffuseTex", 2D) = "white" {}
        _SpecularMaskTex("_SpecularMaskTex", 2D) = "white" {}
        _SpecularPower("_SpecularPower", Float) = 20
        _SpecularNormFactor("_SpecularNormFactor", Float) = 1
    
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

            TEXTURE2D(_DiffuseTex);         SAMPLER(sampler_DiffuseTex);
            TEXTURE2D(_SpecularMaskTex);    SAMPLER(sampler_SpecularMaskTex);

            CBUFFER_START(UnityPerMaterial)
            half _SpecularPower;
            half _SpecularNormFactor;
            CBUFFER_END
                
            struct APPtoVS
            {
                half4 positionOS    : POSITION;
                half3 normalOS      : NORMAL;
                half2 uv            : TEXCOORD0;
            };

            struct VStoFS
            {
                half4 positionCS          : SV_POSITION;
                half2 uv                  : TEXCOORD0;
                half3 N                   : TEXCOORD1;
                half3 H_Sun               : TEXCOORD2;
                half3 H_Points            : TEXCOORD3;
                half3 Diffuse_Sun         : TEXCOORD4;
                half3 Diffuse_Points      : TEXCOORD5;
            };

            const static half3 DIR_UP = half3(0, 1, 0);

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                Light mainLight = GetMainLight();

                half3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);

                half3 N = TransformObjectToWorldNormal(IN.normalOS);
                half3 V = GetWorldSpaceViewDir(positionWS);
                half3 L = mainLight.direction;

                half3 L_points = half3(0, 0, 0);

                uint additionalLightsCount = min(GetAdditionalLightsCount(), 3);
                for (uint i = 0; i < additionalLightsCount; ++i)
                {
                    Light additionalLight = GetAdditionalLight(i, positionWS);
                    half3 L_attenuated = additionalLight.direction * additionalLight.distanceAttenuation;

                    OUT.Diffuse_Points += saturate(dot(N, L_attenuated)) * additionalLight.color;
                    L_points += L_attenuated;
                }
                OUT.H_Points = normalize(L_points) + V;

                OUT.Diffuse_Sun = saturate(dot(N, L * mainLight.distanceAttenuation)) * mainLight.color;
                OUT.H_Sun = normalize(L + V);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                OUT.N = N;

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 N = normalize(IN.N);
                half3 H_Sun = normalize(IN.H_Sun);
                half3 H_Points = normalize(IN.H_Points);

                
                half3 diffuseTex = SAMPLE_TEXTURE2D(_DiffuseTex, sampler_DiffuseTex, IN.uv).rgb;
                half3 diffuse = diffuseTex * (IN.Diffuse_Sun + IN.Diffuse_Points);


                half specularMaskTex = SAMPLE_TEXTURE2D(_SpecularMaskTex, sampler_SpecularMaskTex, IN.uv).r;
                half2 highlights;
                highlights.x = pow(saturate(dot(N, H_Sun)), _SpecularPower);
                highlights.y = pow(saturate(dot(N, H_Points)), _SpecularPower);
                highlights *= _SpecularNormFactor;
                half3 specular = specularMaskTex * ((IN.Diffuse_Sun * highlights.x) + (IN.Diffuse_Points * highlights.y));

                half3 result = diffuse + specular;
                return half4(result, 1);
            }
            ENDHLSL
        }
    }
}
