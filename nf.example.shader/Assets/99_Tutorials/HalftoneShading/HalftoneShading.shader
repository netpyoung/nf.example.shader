Shader "HalftoneShading"
{
    // ref:
    // - https://www.ronja-tutorials.com/post/040-halftone-shading/
    // - https://blog.naver.com/mnpshino/221481588595

    Properties
    {
        [NoScaleOffset] _PatternTex ("Pattern Texture", 2D) = "white" {}

        _Tilling("Tilling", Range(0, 100)) = 80
        _RemapInputMin("Remap input min value", Range(0, 1)) = 0
        _RemapInputMax("Remap input max value", Range(0, 1)) = 1
        _RemapOutputMin("Remap output min value", Range(0, 1)) = 0
        _RemapOutputMax("Remap output max value", Range(0, 1)) = 1
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_PatternTex);     SAMPLER(sampler_PatternTex);

            CBUFFER_START(UnityPerMaterial)
                half _Tilling;
                half _Substract;
                half _RemapInputMin;
                half _RemapInputMax;
                half _RemapOutputMin;
                half _RemapOutputMax;
            CBUFFER_END

            struct APPtoVS
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normal       : NORMAL;
            };

            struct VStoFS
            {
                float4 positionCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 N            : TEXCOORD1;
                float4 positionNDC  : TEXCOORD2;
            };

            VStoFS vert(APPtoVS IN)
            {
                VStoFS OUT;
                ZERO_INITIALIZE(VStoFS, OUT);

                VertexPositionInputs vertexInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = vertexInputs.positionCS;
                OUT.uv = IN.uv;
                OUT.N = TransformObjectToWorldDir(IN.normal);
                OUT.positionNDC = vertexInputs.positionNDC;

                return OUT;
            }
            
            half Mapping(half input, half inMin, half inMax, half outMin, half outMax)
            {
                half relativeValue = (input - inMin) / (inMax - inMin);
                return lerp(outMin, outMax, relativeValue);
            }

            half4 frag(VStoFS IN) : SV_Target
            {
                half aspect = _ScreenParams.x / _ScreenParams.y;

                half2 screenUV = IN.positionNDC.xy / IN.positionNDC.w;

                half2 patternUV = screenUV * half2(aspect, 1) * _Tilling;

                half patternValue = SAMPLE_TEXTURE2D(_PatternTex, sampler_PatternTex, patternUV).r;
                
                Light light = GetMainLight();
                half3 L = light.direction;
                half3 N = normalize(IN.N);

                half NdotL = max(0, dot(N, L));
                
                half lightIntensity = NdotL * 0.5 + 0.5;

                // ref: float3 step(float3 a, float3 x) => x >= a;
                // half stepped = step(patternValue, lightIntensity);
                // return half4(stepped, stepped, stepped, 1);

                patternValue = Mapping(patternValue, _RemapInputMin, _RemapInputMax, _RemapOutputMin, _RemapOutputMax);

                // ref: float3 fwidth(float3 a) => abs(ddx(a)) + abs(ddy(a));
                half patternAdjust = fwidth(patternValue) * 0.5;
                half patterned = smoothstep(patternValue - patternAdjust, patternValue + patternAdjust, lightIntensity);

                half3 finalColor = patterned;

                return half4(finalColor, 1);
            }
            ENDHLSL
        }
    }
}
