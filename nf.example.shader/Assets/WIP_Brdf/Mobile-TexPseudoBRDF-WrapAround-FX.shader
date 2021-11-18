Shader "MADFINGER/Characters/BRDFLit FX (Supports Backlight)"
{
    Properties
    {
        _MainTex("Base (RGB) Gloss (A)", 2D) = "grey" {}
        [Normal] _BumpMap("Normalmap", 2D) = "bump" {}
        _BRDFTex("NdotL NdotH (RGB)", 2D) = "white" {}
        _NoiseTex("Noise tex", 2D) = "white" {}
        _LightProbesLightingAmount("Light probes lighting amount", Range(0,1)) = 0.9
        _FXColor("FXColor", Color) = (0,0.97,0.89,1)
        _TimeOffs("Time offs", Float) = 0
        _Duration("Duration", Float) = 2
        _Invert("Invert", Float) = 0
        _GlobalTime("_GlobalTime", Float) = 0
            
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_BRDFTex);        SAMPLER(sampler_BRDFTex);
            TEXTURE2D(_BumpMap);        SAMPLER(sampler_BumpMap);
            TEXTURE2D(_NoiseTex);       SAMPLER(sampler_NoiseTex);

            CBUFFER_START(UnityPerMaterial)
            half4 _FXColor;
            float _TimeOffs;
            float _Duration;
            float _LightProbesLightingAmount;
            float _Invert;
            float _GlobalTime;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float3 normalOS      : NORMAL;
                float4 tangent      : TANGENT;
                float2 uv            : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS       : SV_POSITION;
                half3 SHLightingColor   : COLOR0;

                float2 uv_MainTex       : TEXCOORD0;
                float2 uv_BumpMap       : TEXCOORD1;
                half Threshold          : TEXCOORD2;
                half3 V                 : TEXCOORD3;

                float3 T                : TEXCOORD4;
                float3 B                : TEXCOORD5;
                float3 N                : TEXCOORD6;
            };


            inline void ExtractTBN(in half3 normalOS, in float4 tangent, inout half3 T, inout half3  B, inout half3 N)
            {
                N = TransformObjectToWorldNormal(normalOS);
                T = TransformObjectToWorldDir(tangent.xyz);
                B = cross(N, T) * tangent.w * unity_WorldTransformParams.w;
            }

            inline half3 CombineTBN(in half3 tangentNormal, in half3 T, in half3  B, in half3 N)
            {
                return mul(tangentNormal, float3x3(normalize(T), normalize(B), normalize(N)));
            }

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);
                float3 wrldNormal = TransformObjectToWorldNormal(IN.normalOS);
                float3 SHLighting = SampleSH(wrldNormal);
                float  t = saturate((_TimeOffs + _GlobalTime) / _Duration);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.SHLightingColor = saturate(SHLighting + (1 - _LightProbesLightingAmount).xxx);
                OUT.Threshold = _Invert > 0 ? 1 - t : t;
                OUT.uv_MainTex = IN.uv;
                OUT.uv_BumpMap = IN.uv;
                OUT.V = GetWorldSpaceViewDir(TransformObjectToWorld(IN.positionOS.xyz));
                ExtractTBN(IN.normalOS, IN.tangent, OUT.T, OUT.B, OUT.N);

                return OUT;
            }

            
            inline half4 LightingMyPseudoBRDF(half3 lightDir, half3 viewDir, half atten, half3 albedo, half3 N, half3 gloss, half alpha)
            {
                half3 halfDir = normalize(lightDir + viewDir);

                half nl = dot(N, lightDir);
                half nh = dot(N, halfDir);
                half4 l = SAMPLE_TEXTURE2D(_BRDFTex, sampler_BRDFTex, float2(nl * 0.5 + 0.5, nh));

                half4 c;
                c.rgb = albedo * (l.rgb + gloss * l.a) * 2;
                c.a = alpha;
                return c;
            }



            half4 frag(VStoFS IN) : SV_Target
            {
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv_MainTex);
                half3 normalTex = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, IN.uv_BumpMap));

            #if 0
                half noiseTex = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.uv_MainTex * 2).a;
            #else
                half noiseTex = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, IN.uv_MainTex * 2).r;
            #endif

                Light light = GetMainLight();

                half3 N = CombineTBN(normalTex, IN.T, IN.B, IN.N);
                half3 L = normalize(light.direction);
                half3 V = normalize(IN.V);

                half threshold = IN.Threshold;
                half killDiff = noiseTex - threshold;
                half border = 1 - saturate(killDiff * 4);
                border *= border;
                border *= border;

                half3 Albedo = mainTex.rgb * IN.SHLightingColor;
                half Gloss = mainTex.a;
                half Alpha = noiseTex > threshold;
                half3 Emission = _FXColor.xyz * border;

                return LightingMyPseudoBRDF(L, V, light.distanceAttenuation, Albedo, N, Gloss, Alpha) + half4(Emission, 0);
            }
            ENDHLSL
        }
    }
}
