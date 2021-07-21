Shader "PlanarShadow" 
{
    // ref:
    // 실시간 그림자를 싸게 그리자! 평면상의 그림자 ( Planar Shadow for Skinned Mesh) 
    //   - https://ozlael.tistory.com/10
    //   - https://github.com/ozlael/PlannarShadowForUnity
    // 	Unity Shader - Planar Shadow - 平面阴影 （References 未看完）
    //   - https://blog.csdn.net/linjf520/article/details/112979847

    Properties
    {
        _ShadowColor ("Shadow Color", Color) = (0, 0, 0, 1)
        _PlaneHeight ("planeHeight", Float) = 0
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
            Name "PLANAR_SHADOW"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            ZWrite On
            ZTest LEqual 
            Blend SrcAlpha OneMinusSrcAlpha

            Stencil
            {
                Ref 0
                Comp Equal
                Pass IncrWrap
                ZFail Keep
            }

            HLSLPROGRAM
            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _ShadowColor;
            half _PlaneHeight;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS : POSITION;
            };

            struct VStoFS
            {
                float4 positionCS : SV_POSITION;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                Light light = GetMainLight();
                half3 L = light.direction;

                half3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                half opposite = positionWS.y - _PlaneHeight;
                half cosTheta = -L.y;
                half hypotenuse = opposite / cosTheta;

                positionWS += (L * hypotenuse);
                positionWS.y = _PlaneHeight;

                OUT.positionCS = TransformWorldToHClip(positionWS);
                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                return _ShadowColor;
            }
            ENDHLSL
        }
    }
}
