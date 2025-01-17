﻿Shader "grass_boom"
{
    // ref: 유니티 - 폭발에 반응하는 grass 쉐이더 : https://blog.naver.com/daehuck/222413632188
    // ref: Creating Interactive Grass in Unreal Engine 4: https://www.raywenderlich.com/6314-creating-interactive-grass-in-unreal-engine-4

    // RenderTexture 카메라의 렌더러가 URP기본렌더러(Linear공간의 렌더러)를 이용하면, 후처리로 pow(x, 2.2)를 적용시킨다.
    // 이 때문에 FlowTexture의 기본 색(0.5, 0.5, 0)을 표현하기 위해서는,
    // 전처리(pow(x, 1/2.2))가 적용된 값 (0.72974, 0.72974, 0)을 이용하도록 한다.

    // 첨부:
    // // 처음에는 RenderTexture의 ColorFormat의 Linear스페이스 문제로 보고 UNORM을 적용 하였으나,
    // // 카메라의 URP렌더러의 처리 후 RT에 저장됨으로 ColorFormat 문제는 아님.
    // // 다만, FlowTexture는 RGBA중 B/A채널은 사용 안하므로, RG만 있는 텍스쳐를 사용하는게 용량면에서 이득.

    // RenderTexture size: 128 x 128
    // - R16G16_UNORM        : 64kb 
    // - R32G32_SFloat       : 128kb 
    // - R32G32B32A32_SFloat : 256kb

    // >>> pow(0.5, 1/2.2)
    // 0.7297400528407231
    // >>> pow(0.7297400528407231, 2.2)
    // 0.49999999999999994
    // >>> pow(0.72974, 2.2)
    // 0.4999999203486329
    // >>> pow(0.72973, 2.2)
    // 0.4999848466130494

    Properties
    {
        _FxRenderTex("_FxRenderTex", 2D) = "white" {}
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

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_FxRenderTex);    SAMPLER(sampler_FxRenderTex);

            CBUFFER_START(UnityPerMeterial)
            half4 _MainTex_ST;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS    : POSITION;
                float2 uv            : TEXCOORD0;
            };

            struct VStoFS
            {
                float4 positionCS    : SV_POSITION;
                float2 uv            : TEXCOORD0;
            };

            float3 RotateAboutAxis(
                in float3 position,
                in float3 positionOnAxis,
                in float3 rotationAxis,
                in float rotationAngle)
            {
                float3 closestPointOnAxis = positionOnAxis + rotationAxis * dot(rotationAxis, position - positionOnAxis);
                float3 axisU = position - closestPointOnAxis;
                float3 axisV = cross(rotationAxis, axisU);

                float s;
                float c;
                sincos(rotationAngle, s, c);

                float3 rotated = axisU * c + axisV * s;
                return (closestPointOnAxis + rotated);
            }

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);

                // positionWS : [5, -5] => [0.5, -0.5] => [1, -1]
                float2 uv_fxRenderTex = positionWS.xz * 0.1 + 0.5;
                // 렌더카메라가 180도 회전 되어있다면 RotateDegree함수 이용하여 회전된 값을 얻어오자.
                // uv_fxRenderTex = RotateDegrees(uv_fxRenderTex, 0.5, 180);

                float2 fxRenderTex = SAMPLE_TEXTURE2D_LOD(_FxRenderTex, sampler_FxRenderTex, uv_fxRenderTex, 0).rg;
                fxRenderTex = fxRenderTex * 2 - 1; // [0, 1] => [-1, 1]

                float3 forceDir = normalize(float3(fxRenderTex.r, 0, fxRenderTex.g));
                float forceStrength = length(fxRenderTex); // [0, 1]
                float3 upDir = float3(0, 1, 0);
                
                float rotationAngleMax = radians(-90);

                float3 rotationAxis = cross(forceDir, upDir);
                float rotationAngle = forceStrength * rotationAngleMax;

                // _m00, _m01, _m02, _m03
                // _m10, _m11, _m12, _m13
                // _m20, _m21, _m22, _m23
                // _m30, _m31, _m32, _m33
                float3 objectRootPositionWS = UNITY_MATRIX_M._m03_m13_m23;
                float3 RotatedPositionWS= RotateAboutAxis(positionWS, objectRootPositionWS, rotationAxis, rotationAngle);

                OUT.positionCS = TransformWorldToHClip(RotatedPositionWS);
                OUT.uv = IN.uv;

                return OUT;
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                return half4(0, 0.5, 0, 1);
            }
            ENDHLSL
        }
    }
}
