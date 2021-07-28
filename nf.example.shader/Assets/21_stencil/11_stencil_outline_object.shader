Shader "11_stencil_outline_object"
{
    // ref: https://chulin28ho.tistory.com/426

    Properties
    {
        _OutlineWidth("_OutlineWidth", Float) = 5
        _OutlineColor("_OutlineColor", Color) = (1, 1, 1, 1) }

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

            ZTest Always
            ZWrite Off
            Cull Front

            Stencil
            {
                Ref 1
                Comp Equal
            }

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float _OutlineWidth;
            float4 _OutlineColor;
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

                half4 normalCS = TransformObjectToHClip(IN.normal);
                half2 offset = normalize(normalCS.xy) / _ScreenParams.xy * (2 * _OutlineWidth) * OUT.positionCS.w;

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
            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
            }

            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            Stencil
            {
                Ref 2
                Comp Always
                ZFail Replace
            }
            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


            CBUFFER_START(UnityPerMaterial)
            float _OutlineWidth;
            float4 _OutlineColor;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                return 1;
            }
            ENDHLSL
        }
    }
}
