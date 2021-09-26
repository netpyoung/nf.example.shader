Shader "example/Sky_Backdrop"
{
    Properties
    {
        _SkyColor_DaytimeTop("_SkyColor_DaytimeTop", Color) = (0.7, 0.9, 0.9, 1)
        _SkyColor_DaytimeMiddle("_SkyColor_DaytimeMiddle", Color) = (0, 0.7, 0.95, 1)
        _SkyColor_DaytimeBottom("_SkyColor_DaytimeBottom", Color) = (0.35, 0.35, 0.35, 1)
        _SkyColor_Sunset("_SkyColor_Sunset", Color) = (0.9, 0.4, 0.05, 1)
        _SkyColor_Night("_SkyColor_Night", Color) = (0.05, 0.15, 0.25, 1)

        // Control Sun
        _ControlledDaytime("_ControlledDaytime", Range(0.0, 1.0)) = 0.15
        _ControlledSunColor("_ControlledSunColor", Color) = (1, 0, 0, 1)

                _MainTex("texture", 2D) = "white" {}

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
            
            #define SHORT_TWO_PI      6.2831853

            const static half3 DIR_UP = half3(0, 1, 0);
            const static half3 DIR_DOWN = half3(0, -1, 0);

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            half _ControlledDaytime;
            half3 _SkyColor_DaytimeTop;
            half3 _SkyColor_DaytimeMiddle;
            half3 _SkyColor_DaytimeBottom;
            half3 _SkyColor_Sunset;
            half3 _SkyColor_Day;
            half3 _SkyColor_Night;

            struct APPtoVS
            {
                half4 positionOS    : POSITION;
                half2 uv            : TEXCOORD0;
            };

            struct VStoFS
            {
                half4 positionCS    : SV_POSITION;
                half2 uv            : TEXCOORD0;
                half3 positionWS    : TEXCOORD1;
                half3 V             : TEXCOORD2;
                half3 L_Sun         : TEXCOORD3;
                half3 colorLight    : COLOR0;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.V = normalize(GetWorldSpaceViewDir(OUT.positionWS));
                
                half rad =  _ControlledDaytime * SHORT_TWO_PI;
                half s;
                half c;
                sincos(rad, s, c);
                OUT.L_Sun.x = -c;
                OUT.L_Sun.y = s;
                OUT.L_Sun.z = 0;

                Light light = GetMainLight();
                // OUT.L_Sun = light.direction;
                OUT.colorLight = light.color;

                half3 pp = normalize(OUT.positionWS);
                OUT.uv = pp.xz / abs(pp.y);

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

            half3 Desaturation(half3 color, half desaturation)
            {
                half luma = dot(color, half3(0.2126729, 0.7151522, 0.0721750));
                return lerp(color, luma, desaturation);
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half3 V = normalize(IN.V);
                half3 L_Sun = normalize(IN.L_Sun);
                

                half daytimeGradient            = max(0, L_Sun.y);                   // 낮시간 변화 // max(0, dot(-L, DIR_DOWN));
                half skybox_MidTopGradient      = max(0, -V.y);                      // 하늘쪽 변화 // max(0, dot(-V, DIR_UP));
                half skybox_HorizBottomGradient = pow(1 - skybox_MidTopGradient, 8); // 바닥 + 수평 변화

                // 빛이 바라보는 반대 방향에 해를 위치 시킨다.
                half sunGradient = dot(-L_Sun, V);
                half sun = pow(saturate(sunGradient), 20);
                //return sun;

                // 노을의 빛의 퍼짐을 표현하기 위해, 노을색과 붉기를 조절한 빛의 색을 섞는다.
                half _SunsetRedness = 0.5; // [0, 1]
                half invRedness = 1 - _SunsetRedness;
                half3 redishLightColor;
                redishLightColor.r = IN.colorLight.r;
                redishLightColor.g = IN.colorLight.g * invRedness;
                redishLightColor.b = IN.colorLight.b * invRedness * 0.5;

                
                // return half4(redishLightColor, 1);
                half3 sunsetColor = lerp(_SkyColor_Sunset, redishLightColor, sun);
                // return half4(sunsetColor* skybox_MidTopGradient * (1 - daytimeGradient), 1);

                // 낮시간 하늘의 3단계 변화
                // - 카메라가 스카이박스 안쪽에 있으니 `-V`를 시켜주고, 하늘(Up)쪽으로 변화를 넣는다.
                // - 수평선은 역으로해서 역변화를 얻음.
                half3 daytimeSkyMiddleColor       = lerp(_SkyColor_Sunset, _SkyColor_DaytimeMiddle, daytimeGradient);
                half3 daytimeSkyMiddleBottomColor = lerp(daytimeSkyMiddleColor, _SkyColor_DaytimeBottom, skybox_HorizBottomGradient);
                half3 daytimeSkyGradientColor     = lerp(daytimeSkyMiddleBottomColor, _SkyColor_DaytimeTop, skybox_MidTopGradient);


                // 밤낮을 표현하기 위해 빛이 땅을 바라볼때 변화량([0, 1]) 이용.
                half3 skyNightDayColor = lerp(_SkyColor_Night, daytimeSkyGradientColor, daytimeGradient);
                return half4(skyNightDayColor, 1);
            }
            ENDHLSL
        }
    }
}
