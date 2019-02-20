import peasy.*;
PeasyCam cam;

int w =2000;
int h =2000;
int scl = 20;
int cols,rows;
float[][] terrain;
float [][] water;

//water flows slower on land than in sea
float flow_on_land;
float flow_in_sea;


float dynamic = 0;
  
float speed = 0.01;  
void setup(){
  
  cam = new PeasyCam(this, w/2, h/2, 1000, 0);
  cam.setMaximumDistance(3000);
  //frameRate(20);
  //cam.setRotations(0,PI/2,-PI/6);
  //size(600,600,P3D);
  fullScreen(P3D);
  smooth(2);
  cols = w/scl;
  rows = h/scl;
  
  terrain = new float[cols][rows];
  water = new float [2*cols][2*rows];
  
  flow_on_land = -speed;
  flow_in_sea = -speed;
  
}

void draw(){
  int land_factor = 700;
  int water_factor = 75;
  int sea_level = 200;
  int cliff = 25;
  
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
  sphere(30);
  //land
  for (int y = 0; y < rows; y++) 
  {
  for (int x = 0; x < cols; x++) 
  {      
    float nx = (float)scl/20*(float)x/12,ny = (float)scl/20*(float)y/12 ;
    terrain[x][y] = noise(nx, ny);
    //xoff+=0.2;
  }
  //yoff+=0.2;
  }
  
  
  //water
  for (int y = 0; y < 2*rows; y++) 
  {
  for (int x = 0; x < 2*cols; x++) 
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
      //fill(125,125,125);
      //rect(x*scl,y*scl,scl,scl);
      //land, factor is 500
      float[] terrain_color = terrain_gradient(map(land_factor*terrain[x][y]+cliff, 0, land_factor+cliff, 0, 1));
  
      fill(terrain_color[0], terrain_color[1], terrain_color[2], 255);
      noStroke();
      vertex((x+rows/2)*scl, (y+cols/2)*scl, land_factor*terrain[x][y]+cliff);
      vertex((x+rows/2)*scl, (y+cols/2+1)*scl, land_factor*terrain[x][y+1]+cliff);
    }
    endShape();
  }
  
  //water
  for (int y=0; y<2*rows-1; y++)
  {
    beginShape(TRIANGLE_STRIP);
    for (int x=0;x<2*cols; x++)
    {
      fill(20, 20, 200, 75);
      stroke(20, 20, 200, 20);
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
  print(height);
  if (height < 0.7)
  {
  height /= 0.7;
  for (int i=0; i<3; i++)
  {
    terrain_color[i] = colorA[i] + height*(colorB[i]-colorA[i]);
  }
  } 
  
  return terrain_color;
}
