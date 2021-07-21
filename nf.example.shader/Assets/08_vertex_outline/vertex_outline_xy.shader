Shader "NFShader/Outline/vertex_outline_xy"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _OutlineWidth("_OutlineWidth", Float) = 0.02
        _OutlineColor("_OutlineColor", Color) = (1, 1, 1, 1)
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
            Name "VERTEX_OUTLINE_XY_BACK"

            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
            }

            Cull Front

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;

            float _OutlineWidth;
            float4 _OutlineColor;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normal       : NORMAL;
            };

            struct VStoFS
            {
                float4 positionCS   : SV_POSITION;
                float2 universal    : TEXCOORD0;
            };

            inline float2 TransformViewToProjection(float2 v)
            {
                return mul((float2x2)UNITY_MATRIX_P, v);
            }

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);

                // 아웃라인은 2차원이므로. `normalCS.xy`에 대해서만 계산 및 `normalize`.
                // 카메라 거리에 따라 아웃라인의 크기가 변경되는것을 막기위해 `normalCS.w`를 곱해준다.
                // _ScreenParams.xy (x/y는 카메라 타겟텍스쳐 넓이/높이)로 나누어서 [-1, +1] 범위로 만듬.
                // 길이 2인 범위([-1, +1])와 비율을 맞추기 위해 OutlineWidth에 `*2`를 해준다.
                half4 normalCS = TransformObjectToHClip(IN.normal);
                half2 offset = normalize(normalCS.xy) / _ScreenParams.xy * (2 * _OutlineWidth) * OUT.positionCS.w;

                // 버텍스 칼라를 곱해주면서 디테일 조정.
                // offset *= IN.color.r;

                OUT.positionCS.xy += offset;

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                return _OutlineColor;
            }
            ENDHLSL
        }

        Pass
        {
            Name "VERTEX_OUTLINE_XY_FRONT"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Cull Back

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;

            float _OutlineThickness;
            float4 _OutlineColor;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
            }
            ENDHLSL
        }
    }
}
