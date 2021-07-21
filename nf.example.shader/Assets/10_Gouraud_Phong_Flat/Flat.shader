Shader "example/Flat"
{
    Properties
    {
        _MainTex("Texture", 2D)			= "white" {}
        _Ambient("Ambient", Color)		= (1, 1, 1, 1)
        _Diffuse("Diffuse", Color)		= (1, 1, 1, 1)
        _Specular("Specular", Color)	= (1, 1, 1, 1)
        _Ks("Ks", Float)				= 1
        _Kd("Kd", Float)				= 1
        _Ka("Ka", Float)				= 1
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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float3 _Ambient;
            float3 _Diffuse;
            float3 _Specular;
            float _Ks;
            float _Kd;
            float _Ka;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS	: POSITION;
                float2 uv			: TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS	: SV_POSITION;
                float2 uv           : TEXCOORD0;

                float3 positionWS	: TEXCOORD1;
                float3 V            : TEXCOORD2;
                float3 L            : TEXCOORD3;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                
                Light light = GetMainLight();
                OUT.V = GetWorldSpaceViewDir(OUT.positionWS);
                OUT.L = light.direction;
                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 x = ddx(IN.positionWS);
                half3 y = ddy(IN.positionWS);

                half3 N = normalize(-cross(x, y));
                half3 V = normalize(IN.V);
                half3 L = normalize(IN.L);

                half3 R = reflect(-L, N);

                half NdotL = max(0, dot(N, L));
                half RdotV = max(0, dot(R, V));

                half3 diffuseColor = _Ambient * _Ka + _Diffuse * _Kd * NdotL;
                half3 specularColor = _Specular * _Ks * pow(RdotV, 20);

                half4 finalColor = half4(diffuseColor * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb + specularColor, 1);
                return finalColor;
            }
            ENDHLSL
        }
    }
}
