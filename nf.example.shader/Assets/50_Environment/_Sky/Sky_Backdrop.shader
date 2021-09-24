Shader "example/Sky_Backdrop"
{
    Properties
    {
        _SunPosition("_SunPosition", Vector) = (0, 30, 0, 1)
        _SunDegree("_SunDegree", Range(0.0, 1.0)) = 0.05
        _SunColor("_SunColor", Color) = (1, 1, 1, 1)

        _SkyColor_Top("_SkyColor_Top", Color) = (0.7, 0.9, 0.9, 1)
        _SkyColor_Middle("_SkyColor_Middle", Color) = (0, 0.7, 0.95, 1)
        _SkyColor_Bottom("_SkyColor_Bottom", Color) = (0.35, 0.35, 0.35, 1)
        _SkyColor_Sunset("_SkyColor_Sunset", Color) = (0.9, 0.4, 0.05, 1)
        _SkyColor_Day("_SkyColor_Day", Color) = (0, 0.4, 0.75, 1)
        _SkyColor_Night("_SkyColor_Night", Color) = (0.05, 0.15, 0.25, 1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Background+0"
            "RenderType" = "Background"
            "ForceNoShadowCasting" = "True"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            
            Cull Off
            ZWrite Off
            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            float3 _SkyColor_Top;
            float3 _SkyColor_Middle;
            float3 _SkyColor_Bottom;
            float3 _SkyColor_Sunset;
            float3 _SkyColor_Day;
            float3 _SkyColor_Night;

            float3 _SunPosition;
            float _SunDegree;
            float3 _SunColor;

            const static float3 DIR_UP = float3(0, 1, 0);
            const static float3 DIR_DOWN = float3(0, -1, 0);

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float3 positionWS    : TEXCOORD1;
                float3 V             : TEXCOORD2;
                float3 L             : TEXCOORD3;
                float3 colorLight    : TEXCOORD4;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.V = normalize(GetWorldSpaceViewDir(OUT.positionWS));
                Light light = GetMainLight();
                OUT.L = light.direction;
                OUT.colorLight = light.color;
                return OUT;
            }

            inline half n8Approximation(half x)
            {
                // n | 8
                // m | 4
                //     pow(x, n)
                //     pow(x, 18)
                //     pow(max(0, Ax        + B     ), m)
                return pow(max(0, 1.838 * x + -0.838), 4);
            }

            float3 Desaturation(float3 color, float desaturation)
            {
                float luma = dot(color, float3(0.2126729, 0.7151522, 0.0721750));
                return lerp(color, luma, desaturation);
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                float3 V = normalize(IN.V);
                float3 L = normalize(IN.L);

                float LdotV = dot(-L, V);
                float VdotDown = max(0, dot(V, DIR_DOWN));
                float LdotUp= max(0, dot(L, DIR_UP));
                float LdotDown = max(0, dot(-L, DIR_DOWN));

                float _SunSetFallOff = 2;
                // SkyColor
                float3 skyDayNightColor = lerp(_SkyColor_Night, _SkyColor_Day, saturate(LdotUp));
                return half4(skyDayNightColor, 1);

                // float skyFallOff = pow(1 - abs(LdotDown), _SunSetFallOff);
                float skyFallOff = pow(LdotUp, _SunSetFallOff);
                // return skyFallOff;

                // Desaturation
                half2 skyboxUV = normalize(IN.positionWS).xy;
                float _LowSkyDesaturation = 0.4;//  [0.4, 1]
                float _LowSkyBrightness = 0.15;//[0.15, 1]
                float horizon = saturate((1 - abs(skyboxUV.y)) * _LowSkyDesaturation);
                float3 horizonBright = saturate((horizon * _LowSkyBrightness) + Desaturate(skyDayNightColor, pow(horizon, 0.33)));
                // return float4(horizonBright, 1);

                // Sunset
                float _SunsetRedness = 0.5; // [0, 1]
                half invRedness = 1 - _SunsetRedness;
                float3 redishColor;
                redishColor.r = IN.colorLight.r;
                redishColor.g = IN.colorLight.g * invRedness;
                redishColor.b = IN.colorLight.b * invRedness * 0.5;
                // return half4(redishColor, 1);

                // return LdotV;
                float3 sunsetGradient = lerp(_SkyColor_Sunset, redishColor, pow(LdotV, 7));

                float3 ss = lerp(horizonBright, sunsetGradient, skyFallOff);
                return half4(sunsetGradient, 1);
                // return 1 - abs(skyboxUV.y);
                return 1;

            }
            ENDHLSL
        }
    }
}
