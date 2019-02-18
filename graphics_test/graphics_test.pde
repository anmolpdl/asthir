//import queasycam.*;
import peasy.*;

PeasyCam cam;
//QueasyCam camera;

//global variables
int cols, rows;
int scl = 20;
int w = 1600;
int h = 1600;
float fill_color;

float dynamic = 0;
float speed;

//to store obtained perlin noise
float[][] terrain;
float[][] water;

float playerSpeed = 1;

void setup() {
  //size(600, 600, P3D);
  fullScreen(P3D);
  
  //anti aliasing
  smooth(8);
  
  cols = w / scl;
  rows = h / scl;
  terrain = new float[cols][rows];
  water = new float[2*cols][2*rows];
  
  // generating terrain once
  //generate_terrain();
  
  
  // camera setup
  //QueasyCam
  /*camera = new QueasyCam(this);
  camera.speed = 5;
  camera.sensitivity = 0.5;*/
  
  //PeasyCam
  cam = new PeasyCam(this, w/2, h/2, 800, 0);
  cam.setMaximumDistance(2000);
  cam.setRotations(0,PI/2,-PI/6);
  //cam.setYawRotationMode();
  
  //CustomCam
  
  // set speed
  //speed = 0.01;
}

void draw() 
{  
  //for custom cam
  /*beginCamera();
  camera();
  //rotateX(PI/8);
  if(key == 'a')
    translate(playerSpeed,0,0);
  switch(key){
    case 'd':
      translate(-playerSpeed,0,0);
    case 'w':
      translate(0,0,playerSpeed);
    case 's':
      translate(0,0,-playerSpeed);
    case ' ':
      translate(0,playerSpeed,0);
  }
  endCamera();*/
  //double pos = cam.getDistance();
  // lights
  ambientLight(172, 136, 111);
  directionalLight(50, 50, 50, 0, 0, -1);
  pointLight(150, 150, 150, w/2, h/2, 100);
  sphere(30);
  
  
  dynamic -= speed;
  float yoff_w = dynamic;
  generate_terrain(dynamic/200);
  
  // generating water each draw()
  for (int y=0; y<2*rows; y++)
  {
    float xoff_w = 0;
    for (int x=0; x<2*cols; x++)
    {
      water[x][y] = map(noise(xoff_w, yoff_w), 0, 1, -50, 50);
      xoff_w += 0.2;
    }
    yoff_w += 0.2;
  }
  background(30);
  stroke(120,20);
  
  //queasycam
  //camera(mouseX, mouseY, (height/2) / tan(PI/6), mouseX, mouseY, 0, 0, 1, 0); 
  //noFill();
  
  
  translate(width/2, height/2); //<>//
  rotateX(PI/3);
  translate(-w/2, -h/2);
  
  
  // plotting water
  for (int y=0; y<2*rows-1; y++)
  {
    beginShape(TRIANGLE_STRIP);
    for (int x=0; x<2*cols; x++)
    {
      fill_color = map(water[x][y], -130, 130, 0, 255);
      fill(20, 20, 200, 75);
      vertex((x-cols/2)*scl, (y-rows/2)*scl, water[x][y]);
      vertex((x-cols/2)*scl, (y+1-rows/2)*scl, water[x][y+1]);
    }
    endShape();
  }
  
  // plotting land
  for (int y=rows/5; y<(rows*4/5)-1; y++)
  {
    beginShape(TRIANGLE_STRIP);
    for (int x=cols/5; x<cols*4/5; x++)
    {
      float[] terrain_color = terrain_gradient(map(terrain[x][y], -100, 250, 0, 1));
      //fill(fill_color, fill_color, fill_color);
      fill(terrain_color[0], terrain_color[1], terrain_color[2], 255);
      vertex(x*scl, y*scl, terrain[x][y]);
      vertex(x*scl, (y+1)*scl, terrain[x][y+1]);
    }
    endShape();
  }
}

float[] terrain_gradient(float height)
{
  float[] terrain_color = {255, 255, 255, 255}; // default snow
  // height between 0 to 1
  
  float[] colorA = {117, 209, 164, 255}; // green
  float[] colorB = {242, 189, 137, 255}; // brown
  
  if (height < 0.7)
  {
  height /= 0.7;
  for (int i=0; i<3; i++)
  {
    terrain_color[i] = colorA[i] + height*(colorB[i]-colorA[i]);
  }
  } 
  
  
  /*if (height < 0.25)
  {
    terrain_color[0] = 20;
    terrain_color[1] = 20;
    terrain_color[2] = 200;
    terrain_color[3] = 255;
  }*/
  
  return terrain_color;
}


void generate_terrain(float yoff_t)
{
  float min_height = -100;
  float max_height = 250;
  float elev;
  
  float a = 0.09;
  float b = 0.94;
  float c = 2.;
  
  //float yoff_t = 0;
  for (int y=rows/5; y<rows*4/5; y++)
  {
    float xoff_t = 0;
    for (int x=cols/5; x<cols*4/5; x++)
    {
      // added octaves
      //elev = noise(xoff_t, yoff_t);
      float e0 = 1 * noise(1 * xoff_t, 1 * yoff_t);
      float e1 = 0.5 * ridge_noise(2 * xoff_t, 2 * yoff_t);
      float e2 = 0.25 * ridge_noise(4 * xoff_t, 4 * yoff_t);
      elev = pow((e0 + e1 + e2)/1.5, 5);
      //float d = 2*max(abs(x-cols/2), abs(y-rows/2)); // manhattan
      float d = 2*sqrt(pow((x - cols/2)/cols, 2) + pow((y - rows/2)/rows, 2)); // euclidean

      elev = (elev + a) * (1 - b*pow(d, c));
      
      
      terrain[x][y] = map(elev, 0, 1, min_height, max_height);
      
      xoff_t += 0.2;
    }
    yoff_t += 0.2;
  }  
}

float ridge_noise(float x, float y)
{
  return 2 * (0.5 - abs(0.5 - noise(x, y)));
}

void keyPressed()
{
  
  if (key == '1' || key == '!')
  {
    speed = 0.01;
  }
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
void keyReleased()
{
  switch(key)
  {
    case 'w':
    case 'a':
    case 's':
    case 'd':
    case ' ':
      key = '\0';
      break;
    default:
      break;
  }
}
