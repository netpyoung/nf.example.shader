#if UNITY_EDITOR
#endif

public class Rand
{

    System.Random _rand;

    public Rand(int seed)
    {
        if (seed < 0)
        {
            _rand = new System.Random();
        }
        else
        {
            _rand = new System.Random(seed);
        }
    }

    public Rand()
    {
        _rand = new System.Random();
    }

    public float value
    {
        get
        {
            // range: [0.0, 1.0]

            // NextDouble() => [0.0, 1.0)
            // TODO
            return (float)_rand.NextDouble();
        }
    }

    public float Range(float min, float max)
    {
        // range: [min, max]

        // NextDouble(min, max) => [min, max)

        // TODO
        return (float)_rand.NextDouble() * (max - min) + min;
    }

    public int Range(int min, int max)
    {
        // range: [min, max)
        return _rand.Next(min, max);
    }
}
