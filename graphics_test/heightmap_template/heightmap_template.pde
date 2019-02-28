//import processing.opengl.*;
//import peasy.*;
//PeasyCam cam;



int w =2000;
int h =2000;
int scl = 20;
int cols,rows;
float[][] terrain;
float [][] water;
int watervol = 2;

//water flows slower on land than in sea
float flow_on_land;
float flow_in_sea;

//to store multiple key presses
boolean[] pressed;

float cameraheight = 650; //works only for w=h=2000

float dynamic = 0;
  
float speed = 0.01;  

//constants for island creation
//a pushes everything up, b pushes edges down, c controls the quickness of dropoff, set a&b to 0 for default
float a = 0.2;
float b = 0.6;
float c = 1;
void setup(){
  //camera(w/2,cameraheight,h/2,w/2,cameraheight,h/2,0,1,0);
  
  //cam = new PeasyCam(this, w/2, h/2, 1000, 0);
  //cam.setMaximumDistance(3000);

  fullScreen(P3D);
  smooth(4);
  cols = w/scl;
  rows = h/scl;
  
  //renderer = (PGraphics3D)g;
  //dynam alloc memory
  terrain = new float[cols][rows];
  water = new float [watervol*cols][watervol*rows];
  pressed = new boolean[256];
  
  flow_on_land = -speed;
  flow_in_sea = -speed;
  
}

void draw(){
  
  int land_factor = 700;
  int water_factor = 75;
  int sea_level = 200;
  int cliff = 25;
  
  custompan();
  dynamic -=speed;
  flow_in_sea = dynamic;
  flow_on_land = dynamic/100;
  
  translate(w/2,h/2);
  rotateX(PI/2);
  translate(-w/2,-h/2);
  //float yoff = 0;
  
  ambientLight(172, 136, 111);
  directionalLight(50, 50, 50, 0, 0, -1);
  pointLight(150, 150, 150, w/2, h/2, 100);
//sphere(30);
  //land
  for (int y = 0; y < rows; y++) 
  {
  for (int x = 0; x < cols; x++) 
  {      
    float nx = (float)scl/20*(float)x/12,ny = (float)scl/20*(float)y/12 ;
    terrain[x][y] = noise(nx+noise(flow_on_land), ny+noise(flow_on_land));
  }
  }
  
  
  //water
  for (int y = 0; y < watervol*rows; y++) 
  {
  for (int x = 0; x < watervol*cols; x++) 
  {      
    float nx = float(scl)/20*(float)x/5,ny = float(scl)/20*(float)y/5 ;
    if ((y<cols/2+cliff || y>3*cols/2-cliff) ||(x<rows/2+cliff ||x>3*rows/2-cliff))
      water[x][y] = noise(nx, ny+flow_in_sea);
    else
      water[x][y] = noise(nx, ny+flow_on_land);
  }
  //flow_in_sea+=0.2;
  }
  background(0);
  //land
  
  for (int y=0; y<rows-1; y++)
  {
    beginShape(TRIANGLE_STRIP);
    for (int x=0;x<cols; x++)
    {

      float dist = sqrt(pow(cols/2-x,2)+pow(rows/2-y,2));
      //mapping upto sqrt(2) instead of 1 for island illusion
      float d = map(dist,0,sqrt(cols/2*cols/2+rows/2*rows/2),0,sqrt(2));
      float dist1 = sqrt(pow(cols/2-x,2)+pow(rows/2-y-1,2));
      float d1 = map(dist1,0,sqrt(cols/2*cols/2+rows/2*rows/2),0,sqrt(2));
      float e =(terrain[x][y] + a)*(1 - b*pow(d,c));
      float e1 =(terrain[x][y+1] + a)* (1- b*pow(d1,c));
      //fill(125,125,125);
      //rect(x*scl,y*scl,scl,scl);
      //land, factor is 500
      float[] terrain_color = terrain_gradient(map(land_factor*e+cliff, 0, land_factor+cliff, 0, 1));
  
      fill(terrain_color[0], terrain_color[1], terrain_color[2], 255);
      noStroke();
      //stroke(terrain_color[0], terrain_color[1], terrain_color[2], 255);
      
      vertex((x+rows/2)*scl, (y+cols/2)*scl, land_factor*e+cliff);
      vertex((x+rows/2)*scl, (y+cols/2+1)*scl, land_factor*e1+cliff);
    }
    endShape();
  }
  
  //water
  for (int y=0; y<watervol*rows-1; y++)
  {
    beginShape(TRIANGLE_STRIP);
    for (int x=0;x<watervol*cols; x++)
    {
      fill(20, 20, 200, 75);
      noStroke();
      //stroke(20, 20, 200, 20);
      //rect(x*scl,y*scl,scl,scl);
      //land, factor is 500
      vertex(x*scl, y*scl, water_factor*water[x][y]+sea_level);
      vertex(x*scl, (y+1)*scl, water_factor*water[x][y+1]+sea_level);
    }
    endShape();
  }
  
}

float [] terrain_gradient(float height)
{
  float[] terrain_color = {255, 255, 255, 255}; // default snow
  // height between 0 to 1
  
  float[] colorA = {0, 255, 0, 255}; // green
  float[] colorB = {242, 189, 137, 255}; // brown
  float[] sand = {224,205,235,255};
  if (height < 0.7 && height >0.3)
  {
  height /= 0.7;
  for (int i=0; i<3; i++)
  {
    terrain_color[i] = colorA[i] + height*(colorB[i]-colorA[i]);
  }
  }
  else if (height<0.3)
  {
    height /= 0.3;
  for (int i=0; i<3; i++)
  {
    terrain_color[i] = sand[i] + height*(colorB[i]-sand[i]);
  }
  } 
  
  return terrain_color;
}

void custompan()
{
  //float cameraZ = ((h/2.0)/tan(PI*60/360));
  if (cameraheight>300)
  {
    camera(w/2,cameraheight,h/2,w/2+1,cameraheight,h/2,0,1,0);
    //defining the perspective projection parameters
    float fov = PI/1.8; // use Pi/1.4-Pi/1.6 for fisheye 
    float cameraZ = (height/2.0) / tan(fov/2.0);
    //projection
    perspective(fov, float(width)/float(height), cameraZ/10.0, cameraZ*10.0);
    
    
    /*
    note: source code for projection(perspective):
    for later reference, can be modified along with frustum
    (that has the actual projection matrix)
    to create other projections*/
    
    /*@Override
    //fov = vertical field of view in degrees
    public void perspective(float fov, float aspect, float zNear, float zFar) 
    {
    float ymax = zNear * (float) Math.tan(fov / 2);
    float ymin = -ymax;
    float xmin = ymin * aspect;
    float xmax = ymax * aspect;
    frustum(xmin, xmax, ymin, ymax, zNear, zFar);
      }
      /*@Override
  public void frustum(float left, float right, float bottom, float top,
                      float znear, float zfar) {
    // Flushing geometry with a different perspective configuration.
    flush();

    cameraFOV = 2 * (float) Math.atan2(top, znear); //atan2(y,x) gives atan(y/x)
    cameraAspect = left / bottom;
    cameraNear = znear;
    cameraFar = zfar;

    float n2 = 2 * znear;
    float w = right - left;
    float h = top - bottom;
    float d = zfar - znear;

    projection.set(n2 / w,       0,  (right + left) / w,                0,
                        0, -n2 / h,  (top + bottom) / h,                0,
                        0,       0, -(zfar + znear) / d, -(n2 * zfar) / d,
                        0,       0,                  -1,                0);

    updateProjmodelview();
  }*/
    
    cameraheight-=speed;
  }
  else
  {
    beginCamera();
    translate(w,cameraheight,h/2);
    rotateY(-speed/100);
    translate(-w,-cameraheight,-h/2);
    endCamera();
  }
}

void keyPressed()
{
  pressed[keyCode] = true;
  switch(key)
  {
    case '1':
    case '!':
      speed = 0.01;
      break;
    case '2':
    case '@':
      speed = 0.025;
      break;
    case '3':
    case '#':
      speed = 0.05;
      break;
    case '4':
    case '$':
      speed = 0.1;
      break;
    case '5':
    case '%':
      speed = 0.25;
      break;
    case '6':
    case '^':
      speed = 0.5;
      break;
    case '7':
    case '&':
      speed = 2;
      break;
    default:
      speed = 0.01;
      break;
  }
}
void keyReleased(){
  pressed[keyCode] = false;
}
