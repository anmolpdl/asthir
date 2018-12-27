import matplotlib.pyplot as plt
import numpy as np
from mpl_toolkits.mplot3d import axes3d

def perlin(x, y, seed=0):
    np.random.seed(seed)
    p = np.arange(256, dtype=int)
    np.random.shuffle(p)
    p = np.stack([p, p]).flatten()
    
    xi = x.astype(int)
    yi = y.astype(int)
    
    xf = x - xi
    yf = y - yi
    
    u = fade(xf)
    v = fade(yf)
    
    n00 = gradient(p[p[xi]+yi], xf, yf)
    n01 = gradient(p[p[xi]+yi+1], xf, yf-1)
    n11 = gradient(p[p[xi+1]+yi+1], xf-1, yf-1)
    n10 = gradient(p[p[xi+1]+yi], xf-1, yf)
    
    x1 = lerp(n00, n10, u)
    x2 = lerp(n01, n11, u)
    
    return lerp(x1, x2, v)
  
def lerp(a, b, x):
    return a + x*(b-a)
  
def fade(t):
    return 6*(t**5)-15*(t**4)+10*(t**3)
  
def gradient(h, x, y):
    vectors = np.array([[0, 1], [0, -1], [1,0], [-1, 0]])
    g = vectors[h%4]
    return g[:, :, 0]*x + g[:, :, 1]*y
    
    
    
if __name__ == '__main__':
    a, b, c = np.indices((15, 15, 15))
    lin = np.linspace(0, 4, 15, endpoint=False)
    x, y = np.meshgrid(lin, lin)

    values = perlin(x, y, seed=77).flatten()
    values = (values+0.4)*10
    values = values.reshape((15, 15))

    cube = c<values[a, b]
    
    fig = plt.figure()
    ax = fig.gca(projection='3d')
    
    ax.voxels(cube, facecolors='#7A88CCE0', edgecolors='#3D4466') # 3d voxels    
    
    # ax.imshow(perlin(x, y, seed=77), origin='upper') # 2d image
    
    plt.show()