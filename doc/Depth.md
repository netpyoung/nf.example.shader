Normalised Device Coordinates (NDC)
(0,0) in the bottom left corner and (1,1) in the top right

|  |  |
|--|--|
|  |  |
float fragmentEyeDepth = -IN.positionVS.z;

float4 positionNDC	= positionCS * 0.5f;
positionNDC.xy 		= float2(positionNDC.x, positionNDC.y * _ProjectionParams.x) + positionNDC.w;
positionNDC.zw 		= positionCS.zw;
OUT.positionNDC 	= positionNDC;

월드좌표 : (월드 위치값xy, 월드깊이값z) => 해당 월드좌표가 박스영역안에 있으면 데칼.
https://github.com/o-l-l-i/ScreenSpaceDecal/blob/master/ScreenSpaceDecal.shader


https://forum.unity.com/threads/decodedepthnormal-linear01depth-lineareyedepth-explanations.608452/#post-4070806
LinearEyeDepth takes the depth buffer value and converts it into world scaled view space depth
0.0 will become the far plane distance value, and 1.0 will be the near clip plane


EyeDepth 카메라 좌표기준 평면에서 직각으로 오브젝트까지 선을그은 거리

Linear01Depth
Linear01Depth mostly just makes the non-linear 1.0 to 0.0 range be a linear 0.0 to 1.0, 


원근 분할(Perspective Divide)
float3 perspectiveDivide = IN.positionNDC.xyz / IN.positionNDC.w;
float2 uv_Screen         = perspectiveDivide.xy;
float depth              = perspectiveDivide.z;
float sceneRawDepth = SampleSceneDepth(uv_Screen);
float sceneEyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
float fragmentEyeDepth = -IN.positionVS.z;
float3 worldPos = _WorldSpaceCameraPos - ((IN.viewDirVector / fragmentEyeDepth) * sceneEyeDepth);



https://github.com/keijiro/DepthInverseProjection


    Direct3D-like, Reversed Z Buffer : 1 at the near plane, 0 at the far plane
    OpenGL-like, Z Buffer : 0 at the near plane, 1 at the far plane
