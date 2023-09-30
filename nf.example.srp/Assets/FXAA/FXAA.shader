Shader "Hidden/FXAA"
{
    // ref: 
    // - https://catlikecoding.com/unity/tutorials/advanced-rendering/fxaa/
    //   - https://bitbucket.org/catlikecodingunitytutorials/custom-srp-17-fxaa/src/master/Assets/Custom%20RP/Shaders/FXAAPass.hlsl
    // - http://blog.simonrodriguez.fr/articles/2016/07/implementing_fxaa.html
    //   - 번역 : https://scahp.tistory.com/68

    Properties
    {
        // Trims the algorithm from processing darks.
        //   0.0833 - upper limit (default, the start of visible unfiltered edges)
        //   0.0625 - high quality (faster)
        //   0.0312 - visible limit (slower)
        // FxaaFloat fxaaQualityEdgeThresholdMin,
        _ContrastThreshold("_ContrastThreshold",Range(0.0312, 0.0833)) = 0.0312

        // The minimum amount of local contrast required to apply algorithm.
        //   0.333 - too little (faster)
        //   0.250 - low quality
        //   0.166 - default
        //   0.125 - high quality 
        //   0.063 - overkill (slower)
        // FxaaFloat fxaaQualityEdgeThreshold,
        _RelativeThreshold("_RelativeThreshold", Range(0.063, 0.333)) = 0.063

        // Choose the amount of sub - pixel aliasing removal.
        // This can effect sharpness.
        //   1.00 - upper limit (softer)
        //   0.75 - default amount of filtering
        //   0.50 - lower limit (sharper, less sub-pixel aliasing removal)
        //   0.25 - almost off
        //   0.00 - completely off
        // FxaaFloat fxaaQualitySubpix,
        _SubpixelBlending("Subpixel Blending", Range(0.0, 1.0)) = 0.75
    }

    SubShader
    {
        Cull Back
        ZWrite Off
        ZTest Off

        HLSLINCLUDE
        #pragma target 3.5
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
        #pragma vertex Vert
        #pragma fragment frag
        ENDHLSL

        Pass // 0
        {
            NAME "PASS_FXAA_LUMINANCE_CONVERSION"

            HLSLPROGRAM
            inline float FxaaLuma(float3 rgb)
            {
                return rgb.g * (0.587 / 0.299) + rgb.r;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float4 blitTex = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord);
                blitTex.a = FxaaLuma(saturate(blitTex.rgb));
                return blitTex;
            }
            ENDHLSL
        }

        Pass // 1
        {
            NAME "PASS_FXAA_APPLY"

            HLSLPROGRAM
            float4 _BlitTexture_TexelSize;
            float _ContrastThreshold;
            float _RelativeThreshold;
            float _SubpixelBlending;

            inline float Luma(float4 rgba)
            {
                return rgba.a;
            }

            float SampleLuminance(float2 uv)
            {
                return Luma(SAMPLE_TEXTURE2D_LOD(_BlitTexture, sampler_PointClamp, uv, 0));
            }

            float SampleLuminance(float2 uv, float2 uvOffset)
            {
                return Luma(SAMPLE_TEXTURE2D_LOD(_BlitTexture, sampler_PointClamp, uv + _BlitTexture_TexelSize.xy * uvOffset, 0));
            }

            struct LuminanceData
            {
                float nw, n, ne;
                float  w, c, e;
                float sw, s, se;
                float highest;
                float lowest;
                float contrast;
            };

            bool IsFailLocalContrastCheck(in LuminanceData l, in float contrastThreshold, in float relativeThreshold)
            {
                float threshold = max(contrastThreshold, relativeThreshold * l.highest);
                return (l.contrast < threshold);
            }

            void FillDirectionalLuminance(inout LuminanceData l, in float2 uv)
            {
                l.n = SampleLuminance(uv, float2(0, -1));
                l.e = SampleLuminance(uv, float2(1, 0));
                l.w = SampleLuminance(uv, float2(-1, 0));
                l.s = SampleLuminance(uv, float2(0, 1));
            }
            
            void FillContrastLuminance(inout LuminanceData l)
            {
                l.highest = max(max(max(max(l.c, l.n), l.e), l.w), l.s);
                l.lowest = min(min(min(min(l.c, l.n), l.e), l.w), l.s);
                l.contrast = l.highest - l.lowest;
            }

            void FillDiagonalLuminance(inout LuminanceData l, in float2 uv)
            {
                l.ne = SampleLuminance(uv, float2(1, -1));
                l.nw = SampleLuminance(uv, float2(-1, -1));
                l.se = SampleLuminance(uv, float2(1, 1));
                l.sw = SampleLuminance(uv, float2(-1, 1));
            }
            
            bool IsHorizontalEdge(in LuminanceData l)
            {
                float edgeH = abs(l.nw + l.sw - 2.0 * l.w) // diagonal-West
                    + abs(l.e + l.w - 2.0 * l.c) * 2.0     // horizontal : 수평
                    + abs(l.ne + l.se - 2.0 * l.e);        // diagonal-East
                float edgeV = abs(l.nw + l.ne - 2.0 * l.n) // diagonal-North
                    + abs(l.n + l.s - 2.0 * l.c) * 2.0     // vertical   : 수직
                    + abs(l.sw + l.se - 2.0 * l.s);        // diagonal-South
                return (edgeH >= edgeV);
            }

            struct EdgeData
            {
                float pixelStep;
                float oppositeLuminance;
                float gradient;
            };

            EdgeData GetEdgeData(in LuminanceData l, in bool isHorizontal)
            {
                float pLuminance = isHorizontal ? l.n : l.e;
                float nLuminance = isHorizontal ? l.s : l.w;
                float pGradient = abs(pLuminance - l.c);
                float nGradient = abs(nLuminance - l.c);

                EdgeData e;
                e.pixelStep = isHorizontal ? _BlitTexture_TexelSize.y : _BlitTexture_TexelSize.x;
                if (pGradient < nGradient)
                {
                    e.pixelStep = -e.pixelStep;
                    e.oppositeLuminance = nLuminance;
                    e.gradient = nGradient;
                }
                else
                {
                    e.oppositeLuminance = pLuminance;
                    e.gradient = pGradient;
                }
                return e;
            }

#define FXAA_QUALITY_LOW 1

#if defined(FXAA_QUALITY_LOW)
    #define EXTRA_EDGE_STEPS 3
    #define EDGE_STEP_SIZES 1.5, 2.0, 2.0
    #define LAST_EDGE_STEP_GUESS 8.0
#elif defined(FXAA_QUALITY_MEDIUM)
    #define EXTRA_EDGE_STEPS 8
    #define EDGE_STEP_SIZES 1.5, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 4.0
    #define LAST_EDGE_STEP_GUESS 8.0
#else
    #define EXTRA_EDGE_STEPS 10
    #define EDGE_STEP_SIZES 1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0
    #define LAST_EDGE_STEP_GUESS 8.0
#endif
            static const float edgeSteps[EXTRA_EDGE_STEPS] = { EDGE_STEP_SIZES };
            float GetEdgeBlend(in LuminanceData l, in EdgeData e, in float2 uv, in bool isHorizontal)
            {
                float edgeLuminance = (l.c + e.oppositeLuminance) * 0.5;
                float gradientThreshold = e.gradient * 0.25;
                float2 uvEdge = uv;
                float2 edgeStep = 0;
                if (isHorizontal)
                {
                    uvEdge.y += e.pixelStep * 0.5;
                    edgeStep.x = _BlitTexture_TexelSize.x;
                }
                else
                {
                    uvEdge.x += e.pixelStep * 0.5;
                    edgeStep.y = _BlitTexture_TexelSize.y;
                }

                float2 puv = uvEdge + edgeStep * edgeSteps[0];
                float pLuminanceDelta = SampleLuminance(puv) - edgeLuminance;
                bool isEndP = abs(pLuminanceDelta) >= gradientThreshold;
                [unroll(16)]
                for (int pi = 1; pi < EXTRA_EDGE_STEPS && !isEndP; ++pi)
                {
                    puv += edgeStep * edgeSteps[pi];
                    pLuminanceDelta = SampleLuminance(puv) - edgeLuminance;
                    isEndP = abs(pLuminanceDelta) >= gradientThreshold;
                }
                if (!isEndP)
                {
                    puv += edgeStep * LAST_EDGE_STEP_GUESS;
                }

                float2 nuv = uvEdge - edgeStep * edgeSteps[0];
                float nLuminanceDelta = SampleLuminance(nuv) - edgeLuminance;
                bool isEndN = abs(nLuminanceDelta) >= gradientThreshold;
                [unroll(16)]
                for (int ni = 1; ni < EXTRA_EDGE_STEPS && !isEndN; ++ni)
                {
                    nuv -= edgeStep * edgeSteps[ni];
                    nLuminanceDelta = SampleLuminance(nuv) - edgeLuminance;
                    isEndN = abs(nLuminanceDelta) >= gradientThreshold;
                }
                if (!isEndN)
                {
                    nuv -= edgeStep * LAST_EDGE_STEP_GUESS;
                }

                float pDistance = (isHorizontal) ? (puv.x - uv.x) : (puv.y - uv.y);
                float nDistance = (isHorizontal) ? (uv.x - nuv.x) : (uv.y - nuv.y);

                float shortestDistance;
                bool isDeltaSign;
                if (pDistance <= nDistance)
                {
                    shortestDistance = pDistance;
                    isDeltaSign = (pLuminanceDelta >= 0);
                }
                else
                {
                    shortestDistance = nDistance;
                    isDeltaSign = (nLuminanceDelta >= 0);
                }

                bool isCenterLuminanceBrighter = (l.c - edgeLuminance >= 0);
                if (isDeltaSign == isCenterLuminanceBrighter)
                {
                    return 0;
                }
                return 0.5 - shortestDistance / (pDistance + nDistance);
            }

            float GetPixelBlend(in LuminanceData l, in float subpixelBlending)
            {
                // Subpixel antialiasing
                // | 1 | 2 | 1 |
                // | 2 | . | 2 |
                // | 1 | 2 | 1 |
                float filter = 2 * (l.n + l.e + l.s + l.w);
                filter += l.ne + l.nw + l.se + l.sw;
                filter *= 1.0 / 12.0;
                filter = abs(filter - l.c);
                filter = saturate(filter / max(0.0001, l.contrast));
                float blendFactor = smoothstep(0.0, 1.0, filter);
                return blendFactor * blendFactor * subpixelBlending;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float4 blitTex = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, IN.texcoord);

                // Local Contrast Check
                LuminanceData l = (LuminanceData) 0;
                l.c = Luma(blitTex);

                FillDirectionalLuminance(l, IN.texcoord);
                FillContrastLuminance(l);
                if (IsFailLocalContrastCheck(l, _ContrastThreshold, _RelativeThreshold))
                {
                    return half4(blitTex.rgb, 1);
                }

                // Vertical/Horizontal Edge Test
                FillDiagonalLuminance(l, IN.texcoord);
                bool isHorizontal = IsHorizontalEdge(l);

                // End-of-edge Search
                EdgeData e = GetEdgeData(l, isHorizontal);

                // Blending
                float edgeBlend = GetEdgeBlend(l, e, IN.texcoord, isHorizontal);
                float pixelBlend = GetPixelBlend(l, _SubpixelBlending);
                float finalBlend = max(pixelBlend, edgeBlend);
                // return edgeBlend;
                // return pixelBlend;
                // return finalBlend;
                
                float2 uv = IN.texcoord;
                if (isHorizontal)
                {
                    uv.y += e.pixelStep * finalBlend;
                }
                else
                {
                    uv.x += e.pixelStep * finalBlend;;
                }
                // return finalBlend;
                // return e.pixelStep;
                float4 tex = SAMPLE_TEXTURE2D_LOD(_BlitTexture, sampler_PointClamp, uv, 0);
                return tex;
            }
            ENDHLSL
        }
    }
}
