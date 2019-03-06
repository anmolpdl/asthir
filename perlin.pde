/*
 * perlin.pde
 *
 * Created : 03/06/2019
 *  Author : n-is
 *   email : 073bex422.nischal@pcampus.edu.np
 */

/**
  * \class Perlin
  * \brief A static class that implements perlin noise.
  *
  * This class is responsible for providing a perlin noise value based on a
  * timestamp. In order to obtain a smooth noise, the get_Noise(timestamp)
  * method of this class can be called. Smooth timestamp, i.e, lower difference
  * in timestamps allows much smoother noise to be generated.
  * 
  * This class also contains get_OctaveNoise method, that gives sum of perlin
  * noises of different octaves.
  */
public static class Perlin {

        private static int[] grad_table_;
        private static int table_size_;

        public static void setup(PApplet pa, int table_size) {

                table_size_ = table_size;
                grad_table_ = new int[table_size];

                // Fill the gradient table using random integers from 0-to-255
                for (int i = 0; i < table_size; ++i) {
                        grad_table_[i] = floor(pa.random(0, 255));
                }
        }

        // 1-D perlin noise implementation
        public static float get_Noise(float x) {

                while(x < 0) {
                        x += (table_size_ - 1);
                }

                // Converting to range (0-to-(table_size - 1))
                int x0 = (int)x % (table_size_ - 1);
                x -= floor(x);
                // Blending the value
                float u = blend_func(x);

                float n0, n1, value;
                n0 = grad(grad_table_[x0], x);
                n1 = grad(grad_table_[x0 + 1], x-1);

                value = linterp(n0, n1, u) * 2;

                // Converting the value to range 0-to-1 from -1-to-1
                value += 1;
                value /= 2.0;

                return value;
        }

        // 2-D Perlin Noise Implementation
        public static float get_Noise(float x, float y) {

                // Converting to positive values in the required range
                while(x < 0) {
                        x += (table_size_ - 1);
                }
                while(y < 0) {
                        y += (table_size_ - 1);
                }

                int x0 = floor(x) % (table_size_ - 1);
                int y0 = floor(y) % (table_size_ - 1);

                x -= floor(x);
                y -= floor(y);

                float sx = blend_func(x);
                float sy = blend_func(y);

                // Taking first gradient
                // Converting values to range 0-(table_size - 1)
                int a = (grad_table_[x0  ] + y0);
                int b = (grad_table_[x0+1] + y0);

                a %= (table_size_ - 1);
                b %= (table_size_ - 1);

                float gax, gay, ga1x, ga1y;
                gax  = grad(grad_table_[a  ], x,   y  );
                gay  = grad(grad_table_[b  ], x-1, y  );
                ga1x = grad(grad_table_[a+1], x,   y-1);
                ga1y = grad(grad_table_[b+1], x-1, y-1);

                float n0 = linterp(gax, gay, sx);
                float n1 = linterp(ga1x, ga1y, sx);

                float value = linterp(n0, n1, sy);

                value += 1;
                value /= 2.0;

                return value;
        }

        // 1-D Perlin Noise with Octave
        public static float get_OctaveNoise(float x, int octaves, float persistence) {

                float total = 0;
                float frequency = 1;
                float amplitude = 1;
                float maxValue = 0;  // Used for normalizing result to 0.0 - 1.0

                for (int i = 0; i < octaves; ++i) {
                        // Adding Noise of different octaves
                        total += get_Noise(x*frequency)*amplitude;

                        maxValue += amplitude;

                        // Amplitude of each successive noise is determined by
                        // the persistence
                        amplitude *= persistence;
                        // We are simply adding noises of frequencies of second
                        // multiple of fundamental frequency.
                        frequency *= 2;
                }

                // To prevent division by 0 error since we are sure taht octave
                // is never 0
                if (octaves == 0) {
                        maxValue = 1;
                }

                return total/maxValue;
        }

        // 2-D Perlin Noise with Octave
        public static float get_OctaveNoise(float x, float y, int octaves, float persistence) {

                float total = 0;
                float frequency = 1;
                float amplitude = 1;
                float maxValue = 0;  // Used for normalizing result to 0.0 - 1.0

                for (int i = 0; i < octaves; ++i) {
                        // Adding Noise of different octaves
                        total += get_Noise(x*frequency, y*frequency)*amplitude;

                        maxValue += amplitude;

                        // Amplitude of each successive noise is determined by
                        // the persistence
                        amplitude *= persistence;
                        // We are simply adding noises of frequencies of second
                        // multiple of fundamental frequency.
                        frequency *= 2;
                }

                // To prevent division by 0 error since we are sure taht octave
                // is never 0
                if (octaves == 0) {
                        maxValue = 1;
                }

                return total/maxValue;
        }

        // Precise method linear interpolation implementation
        // https://en.wikipedia.org/wiki/Linear_interpolation
        private static float linterp(float x, float y, float s) {
                return (1 - s)*x + s*y;
        }

        // We will assign positive gradient to even hash and negative to odds
        private static float grad(int hash, float x) {
                return (hash & 1) == 0 ? x:-x;
        }

        // 2-D grad implementation
        private static float grad(int hash, float x, float y) {
                return ((hash & 1) == 0 ? x : -x) + ((hash & 2) == 0 ? y : -y);
        }

        // Using smoothstep function as a blender
        // https://en.wikipedia.org/wiki/Smoothstep
        private static float blend_func(float t) {
                // We don't need clamping as the input 't' is in range 0-to-1

                // Cubic Hermite interpolation : 3t^2 - 2t^3
                return t*t*(3 - 2*t);

                // Ken Perlin's suggested blender function : 6t^5 - 15t^4 + 10t^3
                // return t*t*t*(6*t*t - 15*t + 10);
        }
}
