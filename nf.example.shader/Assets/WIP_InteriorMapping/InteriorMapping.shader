Shader "InteriorMapping"
{
	// ref: https://forum.unity.com/threads/interior-mapping.424676/#post-2751518
	// 유니티 기본 Cube의 UV가 InteriorMapping에는 적절치 않으므로, 큐브의 다른 면에서 봤을때 방의 위아래가 뒤집히게 나온다.
	// 적절한 UV로 따로 제작해 줘야함.
	Properties
	{
		_RoomAtlasTex("_RoomAtlasTex", 2D) = "white" {}
		_RoomColumnRow("_RoomColumnRow(x:Column, y:Row)", Vector) = (1, 1, 0, 0)
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
			Name "INTERIOR_MAPPING"

			Tags
			{
				"LightMode" = "UniversalForward"
			}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		

			TEXTURE2D(_RoomAtlasTex);		SAMPLER(sampler_RoomAtlasTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _RoomAtlasTex_ST;
				half2 _RoomColumnRow;
			CBUFFER_END

			struct APPtoVS
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
				float3 normalOS		: NORMAL;
				float4 tangentOS	: TANGENT;
			};

			struct VStoFS
			{
				float4 positionCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
				float3 viewDirTS	: TEXCOORD1;
			};

			half random2f(in half2 x)
			{
				return frac(sin(dot(x, float2(12.9898, 78.233))) * 43758.5453);
			}

			VStoFS vert(APPtoVS IN)
			{
				VStoFS OUT;
				ZERO_INITIALIZE(VStoFS, OUT);

				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = TRANSFORM_TEX(IN.uv, _RoomAtlasTex);

				half3 viewDirOS = IN.positionOS.xyz - TransformWorldToObject(GetCameraPositionWS());
				half3 bitangentOS = cross(IN.normalOS, IN.tangentOS.xyz) * IN.tangentOS.w * unity_WorldTransformParams.w;
				OUT.viewDirTS = float3(
					dot(viewDirOS, IN.tangentOS.xyz),
					dot(viewDirOS, bitangentOS),
					dot(viewDirOS, IN.normalOS)
				);
				OUT.viewDirTS *= _RoomAtlasTex_ST.xyx;

				return OUT;
			}

			half4 frag(VStoFS IN) : SV_Target
			{
				half2 roomIndex = floor(IN.uv);   // 정수부.
				roomIndex = floor(_RoomColumnRow * random2f(roomIndex.x + roomIndex.y * (roomIndex.x + 1)));

				// 방의 깊이를 구한다.
				half2 roomDepthUV = (roomIndex + 0.5) / _RoomColumnRow;
				half roomDepth = SAMPLE_TEXTURE2D(_RoomAtlasTex, sampler_RoomAtlasTex, roomDepthUV).a;

				// 깊이에 따른 TangentSpace상의 viewDir를 조정하고,
				half depthScale = (1.0 / (1.0 - roomDepth)) - 1.0;
				IN.viewDirTS.z *= -depthScale;

				// ray위치에서 빔을 쏘아 부딧친 위치(화면에 가장 가까운 벽)를 구한다.
				half2 singleRoom = frac(IN.uv); // 소수부.
				half3 rayPos = half3(singleRoom * 2 - 1, -1);
				half3 id = 1.0 / IN.viewDirTS;
				half3 dist3 = abs(id) - rayPos * id;
				half minDist = min(min(dist3.x, dist3.y), dist3.z);
				half3 hitPos = rayPos + IN.viewDirTS * minDist;

				// FOV(Field of View) 적용.
				half interpRoomDepth = hitPos.z * 0.5 + 0.5;
				half realZ = saturate(interpRoomDepth) / depthScale + 1;
				interpRoomDepth = 1.0 - (1.0 / realZ);
				interpRoomDepth *= depthScale + 1.0;

				half2 interior = hitPos.xy * lerp(1.0, roomDepth, interpRoomDepth);
				interior = interior * 0.5 + 0.5;

				// 아틀라스 상의 UV를 구한다.
				half2 roomAtlasUV = (roomIndex + interior.xy) / _RoomColumnRow;
				half3 roomAtlasTex = SAMPLE_TEXTURE2D(_RoomAtlasTex, sampler_RoomAtlasTex, roomAtlasUV).rgb;

				return half4(roomAtlasTex, 1);
			}
			ENDHLSL
		}
	}
}
