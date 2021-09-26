Shader "example/Hemisphere"
{
    Properties
    {
        _DiffuseTex("_DiffuseTex", 2D) = "white" {}
        _SkyColor("_SkyColor", Color) = (1, 1, 1, 1)
        _GroundColor("_GroundColor", Color) = (1, 1, 1, 1)
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

            CBUFFER_START(UnityPerMaterial)
            half3 _SkyColor;
            half3 _GroundColor;

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
                half3 V                   : TEXCOORD2;
                half3 L                   : TEXCOORD3;
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

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                OUT.N = N;
                OUT.V = V;
                OUT.L = L;

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 N = normalize(IN.N);
                half3 V = normalize(IN.V);
                half3 L = normalize(IN.L);

                half hemiWeight = 0.5 + 0.5 * dot(N, L);
                half3 diffuse = lerp(_GroundColor, _SkyColor, hemiWeight);

                half3 camPositionWS = GetCurrentViewPosition();
                half3 L_VS = GetWorldSpaceViewDir(L);
                half skyWeight = 0.5f + 0.5 * max(0, dot(N, normalize(camPositionWS + L_VS)));
                half groundWeight = 0.5f + 0.5 * max(0, dot(N, normalize(camPositionWS - L_VS)));
                half3 specular = (max(0, pow(skyWeight, _SpecularPower)) + max(0, pow(skyWeight, _SpecularPower)))
                    *_SpecularNormFactor
                    * hemiWeight
                    * diffuse;
                half3 result = diffuse + specular;
                return half4(result, 1);
            }
            ENDHLSL
        }
    }
}
