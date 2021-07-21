Shader "FakeLiquid"
{
    // ref: https://www.patreon.com/posts/18245226

    Properties
    {
        _MainTex("texture", 2D)                                = "white" {}
        _Tint("Tint", Color)                                = (0, 0.5, 0.5, 1)
        _SurfaceColor("_SurfaceColor", Color)                = (0.6, 0.8, 0.8, 1)
        _FoamColor("_FoamColor", Color)                        = (0.6, 0.9, 1, 1)


        _FoamHeight("_FoamHeight", Range(0, 0.1))            = 0.05
        _RimColor("Rim Color", Color)                        = (0.8, 0.8, 1, 1)
        _RimPower("_RimPower", Range(0, 10))                = 2
        _FillAmount("_FillAmount", Range(-10, 10))            = 0.0

        // woobble: 흔들림.
        //[HideInInspector]
        _WobbleX("WobbleX", Range(-1, 1))    = 0.8
        //[HideInInspector]
        _WobbleZ("WobbleZ", Range(-1, 1))    = 0.8
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Pass
        {
            Name "FAKE_LIQUID"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            Zwrite On
            AlphaToMask On // 뚜껑 닫기

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _WobbleX;
            half _WobbleZ;
            half _FillAmount;

            half _FoamHeight;
            half _RimPower;
            half4 _SurfaceColor;
            half4 _RimColor;
            half4 _FoamColor;
            half4 _Tint;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float3 normalOS        : NORMAL;
                float2 uv            : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float2 uv            : TEXCOORD0;
                float3 normalOS        : TEXCOORD1;
                float3 viewDirOS    : TEXCOORD2;
                half fillEdge        : TEXCOORD3;
            };

            half4 RotateAroundYInDegrees(half4 vec4, half degrees)
            {
                half alpha = degrees * PI / 180;
                half s; // sin alpha
                half c; // cos alpha
                sincos(alpha, s, c);

                half2 r = mul(half2x2(c, s, -s, c), vec4.xz);
                return half4(vec4.y, r.x, vec4.z, r.y);
            }

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.normalOS = IN.normalOS;
                OUT.viewDirOS = TransformWorldToObject(GetCameraPositionWS()) - IN.positionOS.xyz;

                half3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                half3 positionWS_X = RotateAroundYInDegrees(half4(positionWS, 0), 0).xyz;
                half3 positionWS_Z = float3 (positionWS_X.y, positionWS_X.z, positionWS_X.x);
                half3 rotatedWS = positionWS + (positionWS_X * _WobbleX) + (positionWS_Z * _WobbleZ);
                OUT.fillEdge = rotatedWS.y + _FillAmount;

                //half3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                //half3 positionWS_X = RotateAroundYInDegrees(half4(positionWS, 0), 360).xyz;
                //half3 positionWS_Z = float3 (positionWS_X.y, positionWS_X.z, positionWS_X.x);
                //half3 adjustedWS = positionWS + (positionWS_X * _WobbleX) + (positionWS_Z * _WobbleZ);
                //OUT.fillEdge = adjustedWS.y + _FillAmount * positionWS.y;

                return OUT;
            }

            half4 frag(VStoFS IN, half facing : VFACE) : SV_Target
            {
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                half main = step(IN.fillEdge, (0.5 - _FoamHeight));
                // return main;

                half foam = step(IN.fillEdge, 0.5) - main;
                // return foam;

                if (facing < 0)
                {
                    return _SurfaceColor * (main + foam);
                }

                half3 N = normalize(IN.normalOS);
                half3 V = normalize(IN.viewDirOS);

                // 유리병 효과의 rim.
                half rim = smoothstep(0.5, 1.0, 1 - pow(saturate(dot(N, V)), _RimPower));
                // return rim;

                half4 riquidColor = (main * mainTex * _Tint) + (foam * _FoamColor);

                return riquidColor + (rim * _RimColor);
            }
            ENDHLSL
        }
    }
}
