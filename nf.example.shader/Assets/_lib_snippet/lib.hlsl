half random2f(in half2 x)
{
    return frac(sin(dot(x, float2(12.9898, 78.233))) * 43758.5453);
}

half random3f(in half3 x)
{
    return frac(sin(dot(x, float3(12.9898, 78.233, 45.5432))) * 43758.5453);
}

half smoothVoronoiV1(in half2 x)
{
    // ref: https://iquilezles.org/www/articles/smoothvoronoi/smoothvoronoi.htm
    half2 p = floor(x);
    half2 f = frac(x);

    half  res = 0.0;
    for (int j = -1; j <= 1; ++j)
    {
        for (int i = -1; i <= 1; ++i)
        {
            half2 b = half2(i, j);
            half2 r = b - f + random2f(p + b);
            float d = dot(r, r);

            res += 1.0 / pow(d, 8.0);
        }
    }
        
    return pow(1.0 / res, 1.0 / 16.0);
}

float smoothVoronoi(in half2 x)
{
    // ref: https://iquilezles.org/www/articles/smoothvoronoi/smoothvoronoi.htm
    half2 p = floor(x);
    half2 f = frac(x);

    half res = 0.0;
    for (int j = -1; j <= 1; ++j)
    {
        for (int i = -1; i <= 1; ++i)
        {
            half2 b = half2(i, j);
            half2 r = b - f + random2f(p + b);
            half d = length(r);

            res += exp(-32.0 * d);
        }
    }
    return -(1.0 / 32.0) * log(res);
}