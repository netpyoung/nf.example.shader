Shader "Ageia/PBRObject/NoneAlpha" 
{
	Properties
	{
		//날씨 선택
		[Header(SelectWeater)]
		[KeywordEnum(BASE, SNOW, RAIN, DESERT)] _WEATHER("SelectWeater(날씨선택)", float) = 0

		[Space(30)]
		_Color ("Color(RGB)", Color) = (0.5,0.5,0.5,0.5)
		_MainTex ("Albedo(RGB)Alpha(A)", 2D) = "white" {}

		//물리계산
		[NoScaleOffset]_PBR("Metallic(R) Smoothness(G) AO(B) Height(A)", 2D) = "black" {}

		[Normal][NoScaleOffset]_Normalmap("_Normalmap", 2D) = "bump" {}

		[HDR]_EmissiveColor("_EmissiveColor", Color) = (0, 0, 0, 0)
		[NoScaleOffset]_Emissive("_Emissive(RGB)", 2D) = "white" {}

		//눈 효과처리
		[Header(SnowSetting___________________________________________________________________________)]
		_SnowView("_SnowView (눈 내린 정도)", Range(0, 1)) = 0.5
		[NoScaleOffset]_SnowGradation("_SnowGradation (눈 그라데이션)", 2D) = "white" {}
		
		//비 효과 처리
		[Space(50)]
		[Header(RainSetting___________________________________________________________________________)]
		_RainAmount("_RainAmount (비가 내린 정도)", Range(0, 1)) = 0.5
		[Normal][NoScaleOffset]_RainNormal("_RainNormal", 2D) = "white" {}
		_UVTiling_Rain("_UVTiling_Rain (비 텍스처 반복량)", Range(0, 2)) = 0.5
		//바닥 비 떨어지는 효과
		[NoScaleOffset]_Raindrop("_Raindrop (비 떨어지는 효과)", 2D) = "white" {}
		//[HideInInspector]
		_RainDropUvTilling ("_RainDropUvTilling (비 바닥에 떨어지는 UV타일링)", Range(0, 1)) = 0.3
			 
		//사막 효과처리
		[Space(50)]
		[Header (DesertSetting___________________________________________________________________________)]
		_DesertView("_DesertView (사막화 정도)", Range(0, 1)) = 0.5
		_UVTilling("_UVTilling (UV반복정도)", Range(0, 0.5)) = 0.234
		//[NoScaleOffset]_DesertAlbedo("_DesertAlbedo", 2D) = "white" {}
		[HideInInspector]_DesertColor("_DesertColor", Color) = (0.67, 0.46, 0.27, 1)
		[Normal][NoScaleOffset]_DesertNormal("_DesertNormal", 2D) = "bump" {}

	}

	SubShader
	{
		Tags
		{
			"RenderType" = "Opaque"
			"RenderPipeline" = "UniversalPipeline"
		}

		Pass
		{
			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			#pragma multi_compile _WEATHER_BASE _WEATHER_SNOW _WEATHER_RAIN _WEATHER_DESERT

			struct Attributes
			{
				float4 positionOS   : POSITION;
				float3 normalOS     : NORMAL;
				float4 tangent      : TANGENT;
				float2 uv           : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionHCS      : SV_POSITION;
				float2 uv               : TEXCOORD0;

				float3 T                : TEXCOORD1;
				float3 B                : TEXCOORD2;
				float3 N                : TEXCOORD3;

				float3 positionWS       : TEXCOORD4;
			};

			TEXTURE2D(_MainTex); //기본컬러
			SAMPLER(sampler_MainTex);
			TEXTURE2D(_NormalMap); //노멀맵
			SAMPLER(sampler_NormalMap);
			TEXTURE2D(_PBR); //물리 계산용 텍스처
			SAMPLER(sampler_PBR);
			TEXTURE2D(_Emissive);
			SAMPLER(sampler_Emissive);
			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
				float4 _NormalMap_ST;
				float4 _PBR_ST;
				float4 _Emissive_ST;
				half4 _Color; //기본컬러에 곱해지는 값.
				half3 _EmissiveColor; //Emissive 컬러
			CBUFFER_END

			////눈 데이터
			// fixed _SnowView; //눈 보이는 정도
			//sampler2D _SnowGradation;

			////비 데이터
			//fixed _RainAmount; //비가 내린 정도
			//sampler2D _RainNormal; //비 노멀
			//fixed _UVTiling_Rain; //비 텍스처 UV반복횟수
			//sampler2D _Raindrop; //비 떨어지는 효과를 위한 텍스처
			//fixed _RainDropUvTilling; //바닥 비 떨어지는 UV크기

			////사막 데이터 
			//fixed _DesertView; //사막화 정도
			//fixed _UVTilling; //UV반복정도
			////sampler2D _DesertAlbedo; //기본텍스처
			//fixed3 _DesertColor; //사막 색상
			//sampler2D _DesertNormal;

			// ----------
			inline void ExtractTBN(in half3 normalOS, in float4 tangent, inout half3 T, inout half3  B, inout half3 N)
			{
				N = TransformObjectToWorldNormal(normalOS);
				T = TransformObjectToWorldDir(tangent.xyz);
				B = cross(N, T) * tangent.w * unity_WorldTransformParams.w;
			}

			inline half3 CombineTBN(in half3 tangentNormal, in half3 T, in half3  B, in half3 N)
			{
				return mul(tangentNormal, float3x3(normalize(T), normalize(B), normalize(N)));
			}

			inline half3x3 GetTBN(in half3 T, in half3 B, in half3 N)
			{
				T = normalize(T);
				B = normalize(B);
				N = normalize(N);
				return float3x3(T, B, N);
			}

			Varyings vert(Attributes IN)
			{
				Varyings OUT = (Varyings)0;
				OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

				ExtractTBN(IN.normalOS, IN.tangent, OUT.T, OUT.B, OUT.N);

				OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);

				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				// #기본 텍스처 처리
				
				half3 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb * _Color.rgb;
				half3 basePBR = SAMPLE_TEXTURE2D(_PBR, sampler_PBR, IN.uv).rgb;
				half4 baseEmissiveAO = SAMPLE_TEXTURE2D(_Emissive, sampler_Emissive, IN.uv);
				
				half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uv));
				half3x3 TBN = GetTBN(IN.T, IN.B, IN.N);
				
				Light light = GetMainLight();
				half3 N = mul(normalTS, TBN);
				half3 L = normalize(light.direction);

				half NdotL = max(0.0, dot(N, L));

				return half4(baseColor * NdotL, 1);
				//half3 baseEmissiveAOFinal = baseEmissiveAO.rgb * _EmissiveColor.rgb;

				//	o.Albedo = BaseColor.rgb;
				//	o.Metallic = PBR_Base.r;
				//	o.Smoothness = PBR_Base.g;
				//	o.Occlusion = PBR_Base.b;
				//	o.Normal = BaseNormal; //1이면 눈 노멀 출력, 0이면 기존 노멀 출력
				//	o.Emission = BaseEmissiveAOFinal.rgb;
				////////////////////////////////
				//////////눈 효과처리//////////
				////////////////////////////////

				//#if _WEATHER_SNOW
				//	//#기본 텍스처 처리
				//	fixed4 BaseColor = tex2D(_MainTex, IN._MainTex) * _Color;
				//	fixed3 BaseNormal = UnpackNormal(tex2D(_Normalmap, IN._MainTex));
				//	fixed4 PBR_Base = tex2D(_PBR, IN._MainTex);
				//	fixed4 BaseEmissiveAO = tex2D(_Emissive, IN._MainTex);
				//	fixed3 BaseEmissiveAOFinal = BaseEmissiveAO.rgb * _EmissiveColor.rgb;

				//	//마스크 최종작업
				//	fixed ViewMaskFinal = saturate((1 - PBR_Base.a) * 3 - 3 + _SnowView * 3.3);

				//	fixed3 GradationFinal = tex2D(_SnowGradation, fixed2(ViewMaskFinal.r, IN._MainTex.y));

				//	//최종 렌더링
				//	o.Albedo = lerp(BaseColor.rgb, GradationFinal, ViewMaskFinal);
				//	o.Metallic = lerp(PBR_Base.r, 0.3, ViewMaskFinal);
				//	o.Smoothness = lerp(PBR_Base.g, 1, ViewMaskFinal);
				//	o.Occlusion = lerp(PBR_Base.b, 1 ,ViewMaskFinal);
				//	o.Normal = lerp(BaseNormal, 1, ViewMaskFinal * 0.7); //1이면 눈 노멀 출력, 0이면 기존 노멀 출력
				//	o.Emission = lerp(BaseEmissiveAOFinal.rgb, 0, ViewMaskFinal);

				//////////////////////////////////
				////////////비 효과처리//////////
				//////////////////////////////////

				//#elif _WEATHER_RAIN

				//	//#기본 텍스처 처리
				//	fixed3 BaseNormal = UnpackNormal(tex2D(_Normalmap, IN._MainTex));
				//	fixed4 PBR_Base = tex2D(_PBR, IN._MainTex);


				//	//비내리는 효과 데이터
				//	//#다중 처리를 위한 월드 좌표데이터
				//	float3 normalWS = normalWSVector(IN, o.Normal);

				//	//땅바닥 마스크처리(Height에 영향 받으며 어두운 면부터 잠겨들어간다.)
				//	fixed RainMaskEarth = PBR_Base.a;

				//	if (RainMaskEarth <= _RainAmount * 1.3)
				//	{
				//		RainMaskEarth = 1;
				//	}
				//	else
				//	{
				//		RainMaskEarth = 0;
				//	}
				//	fixed RainMaskEarthFinal = RainMaskEarth * normalWS.y;
				//	//바닥의 가장 깊은 곳을 완전히 물에 잠겨들도록 처리함.
				//	fixed RainMaskEarth2 = PBR_Base.a;
				//	if (RainMaskEarth2 <= _RainAmount - 0.4)
				//	{
				//		RainMaskEarth2 = 1;
				//	}
				//	else
				//	{
				//		RainMaskEarth2 = 0;
				//	}
				//	fixed RainMaskEarthFinal2 = RainMaskEarth2 * normalWS.y;

				//	//옆면, 아랫면 마스크처리
				//	fixed FrontRender = lerp(0, 1, abs(normalWS.z)); //앞면 렌더링
				//	fixed SideFrontRender = lerp(FrontRender, 1, abs(normalWS.x)); //앞면 + 옆면 렌더링
				//	fixed SideFonrtDownRender = lerp(SideFrontRender, 1, saturate(-normalWS.y)); //앞면 + 옆면 + 밑면 렌더링
				//	//옆면, 아랫면 마스크 최종
				//	fixed SideDownMask = SideFonrtDownRender * _RainAmount;
				//	fixed SideDownMaskHalf = SideDownMask * 0.5;
				//	//땅바닥 젖은 효과 마무리.


				//	//옆면 비 흐르는 효과
				//	//#텍스처 처리용 월드 UV
				//	fixed2 UVtop = fixed2(IN.positionWS.x, IN.positionWS.z); //윗면 UV좌표
				//	fixed2 UVfront = fixed2(IN.positionWS.x, IN.positionWS.y + _Time.z * _RainAmount); //앞면 UV좌표
				//	fixed2 UVside = fixed2(IN.positionWS.y + _Time.z * _RainAmount, IN.positionWS.z); //옆면 UV좌표
				//	//방향에 따른 텍스쳐 출력
				//	fixed3 Texfront = UnpackNormal(tex2D(_RainNormal, UVfront* _UVTiling_Rain)); //정면 텍스처
				//	fixed3 Texside = UnpackNormal(tex2D(_RainNormal, UVside * _UVTiling_Rain)); //옆면 텍스처

				//	//비 벽타고 내리는 효과 노멀처리
				//	fixed3 RainNormalFront = lerp(Texside, Texfront, abs(normalWS.z));
				//	fixed3 RainNormalFinal = lerp(BaseNormal * SideFrontRender, RainNormalFront, SideFrontRender);



				//	//바닥에 비 떨어지는 효과 추가.
				//	//바닥에 비 떨어지는 효과 1번
				//	fixed RainDropTexture = tex2D(_Raindrop, UVtop * _RainDropUvTilling); //텍스처 처리
				//	fixed FracTimeAdd = frac(_Time.y) * 0.4; //반복 그래프
				//	if (RainDropTexture <= FracTimeAdd || RainDropTexture >= FracTimeAdd + 0.02) //빗물을 물방울 모양으로 하기위한 계산식.
				//	{
				//		RainDropTexture = 0;
				//	}
				//	else
				//	{
				//		RainDropTexture = 1;
				//	}
				//	fixed DropRainFinal = RainDropTexture * (1 - frac(_Time.y));
				//	//o.Emission = RainDropTexture * (1 - frac(_Time.y)); // 바닥 비 떨어지는 효과를 위한 테스트용 데이터

				//	//바닥에 비 떨어지는 효과 2번
				//	fixed RainDropTexture2 = tex2D(_Raindrop, fixed2(UVtop.x * _RainDropUvTilling + 0.25, UVtop.y * _RainDropUvTilling + 0.25)); //텍스처 처리
				//	fixed FracTimeAdd2 = frac(_Time.y - 0.5) * 0.4; //반복 그래프 시간차를 둠.
				//	if (RainDropTexture2 <= FracTimeAdd2 || RainDropTexture2 >= FracTimeAdd2 + 0.02) //빗물을 물방울 모양으로 하기위한 계산식.
				//	{
				//		RainDropTexture2 = 0;
				//	}
				//	else
				//	{
				//		RainDropTexture2 = 1;
				//	}
				//	fixed DropRainFinal2 = RainDropTexture2 * (1 - frac(_Time.y - 0.5));
				//	fixed DropRainFinal_f = (DropRainFinal + DropRainFinal2) * saturate(normalWS.y) * _RainAmount;
				//	//바닥에 비 떨어지는 효과 효과 마무리됨.

				//	//기본 텍스처 처리2 (상단에 나머지 데이터 있음.)
				//	fixed2 UVRainNormal = IN._MainTex + RainNormalFinal * _RainAmount * 0.01; //옆면 비 흐르는 효과 UV맵
				//	fixed4 BaseColor = tex2D(_MainTex, UVRainNormal) * _Color + DropRainFinal_f * tex2D(_MainTex, UVRainNormal); //DropRainFinal은 빗방울 떨어지는 효과
				//	fixed4 BaseEmissiveAO = tex2D(_Emissive, UVRainNormal);
				//	fixed3 BaseEmissiveAOFinal = BaseEmissiveAO.rgb * _EmissiveColor.rgb;

				//	//최종 렌더링
				//	o.Albedo = BaseColor.rgb ;
				//	o.Metallic = lerp(PBR_Base.r, 0.75, RainMaskEarthFinal + SideDownMaskHalf);
				//	o.Smoothness = lerp(PBR_Base.g, 1, RainMaskEarthFinal + SideDownMask);
				//	o.Occlusion = PBR_Base.b;
				//	o.Normal = lerp(BaseNormal, 1, RainMaskEarthFinal2 + SideDownMaskHalf) + RainNormalFinal * _RainAmount; //1이면 눈 노멀 출력, 0이면 기존 노멀 출력
				//	o.Emission = BaseEmissiveAOFinal.rgb;

				//////////////////////////////////
				////////////사막효과처리//////////
				//////////////////////////////////
				//#elif _WEATHER_DESERT
				//	//#기본 텍스처 처리
				//	fixed4 BaseColor = tex2D(_MainTex, IN._MainTex) * _Color;
				//	fixed3 BaseNormal = UnpackNormal(tex2D(_Normalmap, IN._MainTex));
				//	fixed4 PBR_Base = tex2D(_PBR, IN._MainTex);
				//	fixed4 BaseEmissiveAO = tex2D(_Emissive, IN._MainTex);
				//	fixed3 BaseEmissiveAOFinal = BaseEmissiveAO.rgb * _EmissiveColor.rgb;

				//	//#다중 처리를 위한 월드 좌표데이터
				//	float3 normalWS = normalWSVector(IN, o.Normal);

				//	//#텍스처 처리용 월드 UV
				//	fixed2 UVtop = fixed2(IN.positionWS.x, IN.positionWS.z) * _UVTilling; //윗면 UV좌표
				//	fixed2 UVfront = fixed2(IN.positionWS.x, IN.positionWS.y) * _UVTilling; //앞면 UV좌표
				//	fixed2 UVside = fixed2(IN.positionWS.z, IN.positionWS.y) * _UVTilling; //옆면 UV좌표

				//	//바닥 사막 텍스처 처리
				//	//fixed3 DesertEarthAlbedoFinal = tex2D(_DesertAlbedo, UVtop); //텍스처 윗면 처리
				//	fixed3 DesertNormalTop = UnpackNormal(tex2D(_DesertNormal, UVtop)); //사막 노멀 텍스처 처리

				//	//옆면, 아랫면 노멀 처리
				//	fixed3 DesertNormalSide = UnpackNormal(tex2D(_DesertNormal, UVside)); //텍스처 옆면 처리
				//	fixed3 DesertNormalFront = UnpackNormal(tex2D(_DesertNormal, UVfront)); //텍스처 앞,뒷면 처리

				//	
				//	//사막 텍스처 최종처리
				//	fixed3 DesertNormalAll = lerp(DesertNormalFront, DesertNormalSide, normalWS.x);
				//	fixed3 DesertNormalAllFinal = lerp(DesertNormalAll, DesertNormalTop, normalWS.y);

				//	//마스크 처리 (바닥 렌더링용)
				//	fixed MaskNoise = saturate((1 - PBR_Base.a) * 5 - 5 + _DesertView * 6); //전체 마스크
				//	fixed MaskNoise2 = saturate((1 - PBR_Base.a) * 5 - 5 + (_DesertView - 0.7) * 6); //옆면 마스크용
				//	fixed MaskEarth = MaskNoise * saturate(normalWS.y); //땅바닥 마스크처리

				//	//마스크처리(옆, 앞면)
				//	fixed MaskSideFront = MaskNoise2 * (1 - saturate(normalWS.y)); //#1바로아래 주석 풀면 적용됨.
				//	//바닥 처리와 옆,앞면 마스크를 더함
				//	fixed MaskAll = MaskEarth 
				//					+ MaskSideFront //#1바로위에 주석 풀면 적용됨.
				//					;

				//	//최종 렌더링
				//	o.Albedo = lerp(BaseColor.rgb, _DesertColor, MaskAll); //기본 Albedo 처리
				//	o.Metallic = lerp(PBR_Base.r, 0, MaskAll);
				//	o.Smoothness = lerp(PBR_Base.g, 0, MaskAll);
				//	o.Occlusion = lerp(PBR_Base.b, lerp(PBR_Base.b, 1, _DesertView), MaskEarth 
				//		+ (MaskSideFront * 0.5) 
				//		//옆면 오클루전을 조금 약하게 하기 위한 계산
				//		)
				//		;
				//	o.Normal = lerp(BaseNormal, lerp(BaseNormal, DesertNormalTop, _DesertView) , MaskEarth);
				//	o.Emission = lerp(BaseEmissiveAOFinal.rgb, 0, MaskAll);


				////가장 기본적인 렌더링
				//#elif _WEATHER_BASE

				//	//#기본 텍스처 처리
				//	fixed4 BaseColor = tex2D(_MainTex, IN._MainTex) * _Color;
				//	fixed3 BaseNormal = UnpackNormal(tex2D(_Normalmap, IN._MainTex));
				//	fixed4 PBR_Base = tex2D(_PBR, IN._MainTex);
				//	fixed4 BaseEmissiveAO = tex2D(_Emissive, IN._MainTex);
				//	fixed3 BaseEmissiveAOFinal = BaseEmissiveAO.rgb * _EmissiveColor.rgb;

				//	o.Albedo = BaseColor.rgb;
				//	o.Metallic = PBR_Base.r;
				//	o.Smoothness = PBR_Base.g;
				//	o.Occlusion = PBR_Base.b;
				//	o.Normal = BaseNormal; //1이면 눈 노멀 출력, 0이면 기존 노멀 출력
				//	o.Emission = BaseEmissiveAOFinal.rgb;

				//#endif
			}
			ENDHLSL
		}
	}
}
