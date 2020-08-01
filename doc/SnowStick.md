눈쌓기

월드 노말 기준으로

눈 각도

float4 snowAngle = float4(0, 1, 0, 1);
float4 worldSnowAngle = mul(normalize(snowAngle), unity_ObjectToWorld);
float snowSize;
float snowHeight;
if (dot(v.normal, worldSnowAngle) >= snowSize)
{
  v.vertex.xyz += (v.normal.xyz * snowHeight);
}

- http://blog.naver.com/plasticbag0/221436480475