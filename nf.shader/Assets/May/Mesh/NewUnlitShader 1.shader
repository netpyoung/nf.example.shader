Shader "NF/Toon/GX"
{
	Properties
	{
		[Header(Diffuse)]
		[NoScaleOffset] _MainTex("Texture", 2D) = "white" {}
		[NoScaleOffset] _SSSTex("_SSSTex", 2D) = "black" {}
		[NoScaleOffset] _LimTex("_LimTex", 2D) = "black" {}
		[NoScaleOffset] _DecalTex("_DecalTex", 2D) = "black" {}
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

			ColorMask RGB
			Cull Front

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
				float3 normal		: NORMAL;
                float4 color        : COLOR;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
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
                OUT.positionCS.xy += normalize(normalCS.xy) * IN.color.r * 0.02;

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				return 0;
			}
			ENDHLSL
		}

		Pass
		{
			Tags
			{
				"LightMode" = "UniversalForward"
			}

			Cull Back

			HLSLPROGRAM
			#pragma target 3.5
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

			#pragma vertex vert
			#pragma fragment frag

			TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);
			TEXTURE2D(_SSSTex);		SAMPLER(sampler_SSSTex);
			TEXTURE2D(_LimTex);		SAMPLER(sampler_LimTex);
			TEXTURE2D(_DecalTex);	SAMPLER(sampler_DecalTex);
			
			CBUFFER_START(UnityPerMaterial)
			CBUFFER_END


            // TEXTURECUBE(unity_SpecCube0); SAMPLER(samplerunity_SpecCube0);
            TEXTURECUBE(unity_SpecCube1); SAMPLER(samplerunity_SpecCube1);

            // real4 unity_SpecCube0_HDR;
            real4 unity_SpecCube1_HDR;
            float4 unity_SpecCube0_BoxMax;          // w contains the blend distance
            float4 unity_SpecCube0_BoxMin;          // w contains the lerp value
            float4 unity_SpecCube0_ProbePosition;   // w is set to 1 for box projection
            float4 unity_SpecCube1_BoxMax;          // w contains the blend distance
            float4 unity_SpecCube1_BoxMin;          // w contains the sign of (SpecCube0.importance - SpecCube1.importance)
            float4 unity_SpecCube1_ProbePosition;   // w is set to 1 for box projection

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float3 normalOS     : NORMAL;
                float4 color        : COLOR;
				float2 uv			: TEXCOORD0;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float2 uv           : TEXCOORD0;
                float4 color        : COLOR;

				float3 N            : TEXCOORD1;
				float3 V            : TEXCOORD2;
                float4 shadowCoord  : TEXCOORD5;
			};

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = IN.uv;
                
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.N = TransformObjectToWorldNormal(IN.normalOS);
                OUT.V = GetWorldSpaceViewDir(positionWS);
                OUT.shadowCoord = TransformWorldToShadowCoord(positionWS);
                OUT.color = IN.color;

				return OUT;
			}

            half4 frag(VStoFS IN) : SV_Target
            {
				half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
				half3 sssTex = SAMPLE_TEXTURE2D(_SSSTex, sampler_SSSTex, IN.uv).rgb;
				half4 limTex = SAMPLE_TEXTURE2D(_LimTex, sampler_LimTex, IN.uv);
				half3 decalTex = SAMPLE_TEXTURE2D(_DecalTex, sampler_DecalTex, IN.uv).rgb;

                half reflectMask = limTex.r;
                half shadowMask = limTex.g;
                half specularMask = limTex.b;
                half strokeMask = limTex.a;

                Light light = GetMainLight(IN.shadowCoord);

                half3 N = normalize(IN.N);
                half3 L = normalize(light.direction);
                half3 V = normalize(IN.V);
                half3 H = normalize(L + V);
                half3 R = reflect(-V, N);

                half NdotH = abs(dot(N, H));
                half NdotV = dot(N, V);
                half NdotL = dot(N, L);

                
                half firstShadowThreshold = 0.4;
                half diffuse = (NdotL * 0.5 + 0.5);
                diffuse = step(firstShadowThreshold, diffuse);

                half specular = reflectMask * step(pow(NdotH, 6), 1 - specularMask) * 0.3;

                half rim = max(0, 1 - max(0, NdotV));
                rim = pow(rim, 10) * 0.2;
                
                float lod = 1;
                float3 probe0 = DecodeHDREnvironment(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, R, lod), unity_SpecCube0_HDR);
                float3 probe1 = DecodeHDREnvironment(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube1, samplerunity_SpecCube1, R, lod), unity_SpecCube1_HDR);
                float3 reflectProbe = lerp(probe1, probe0, unity_SpecCube0_BoxMin.w);
                reflectProbe *= reflectMask;

                half3 sssColor = mainTex * sssTex;
                half3 color = lerp(sssColor, mainTex, diffuse);

                half3 finalColor = color * diffuse + specular + reflectProbe + rim;
                finalColor *= light.color;
                finalColor *= (light.shadowAttenuation * strokeMask);

                return half4(finalColor, 1);
			}
			ENDHLSL
		}
	}
}