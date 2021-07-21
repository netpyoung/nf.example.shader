Shader "BlackHole"
{
    // ref: bzyzhang.github.io/2020/11/28/2020-11-28-（一）顶点动画/
    Properties
    {
        _MainTex("texture", 2D) = "white" {}
        _RightX("Right X", Float) = 1
        _LeftX("Left X", Float) = 0
        _BlackHolePos("Black Hole Pos",Vector) = (1, 1, 1, 1)
        _Control("Control", Range(0, 2)) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "AlphaTest"
            "RenderType" = "TransparentCutout"
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

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float2 uv            : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float2 uv            : TEXCOORD0;
                float3 positionWS    : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;

            half _RightX;
            half _LeftX;
            float4 _BlackHolePos;
            half _Control;
            CBUFFER_END

            half GetNormalizeDistX(half worldX)
            {
                half range = _RightX - _LeftX;
                half distance = _RightX - worldX;
                return saturate(distance / range);
            }

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                half3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                half normalizeDist = GetNormalizeDistX(positionWS.x);

                half3 toBlackHole = TransformWorldToObjectDir(_BlackHolePos.xyz - positionWS.xyz);
                half value = saturate(_Control - normalizeDist);
                IN.positionOS.xyz += toBlackHole * value;

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                clip(_BlackHolePos.x - IN.positionWS.x);

                half3 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}
