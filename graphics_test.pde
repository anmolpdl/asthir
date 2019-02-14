//import queasycam.*;
import peasy.*;

PeasyCam cam;
//QueasyCam camera;

// button stuff begins
int rectX, rectY;
int rectSize = 100;
color rectColor, rectHighlight;
boolean rectOver = false;
// button stuff ends


int cols, rows;
int scl = 20;
int w = 2000;
int h = 1600;
float fill_color;

float dynamic = 0;
float[][] terrain;
float[][] water;

void setup() {
  //size(1200, 1200, P3D);
  fullScreen(P3D);
  smooth(8);
  
  cols = w / scl;
  rows = h / scl;
  terrain = new float[cols][rows];
  water = new float[cols][rows];
  
  // generating terrain once
  //generate_terrain();
  
  
  // camera setup
  
  //camera = new QueasyCam(this);
  //camera.speed = 5;
  //camera.sensitivity = 0.5;
  
  cam = new PeasyCam(this, w/2, h/2, 200, 750);
  //cam.setMinimumDistance(2);
  cam.setMaximumDistance(2000);
  cam.setSuppressRollRotationMode();
  
  // button to speed up time
  rectColor = color(0);
  rectHighlight = color(51);
  rectX = 100;
  rectY = 200;
}

void draw() {
  rect(rectX, rectY, rectSize, rectSize);
  update(mouseX, mouseY);
  if (rectOver) 
  {
    dynamic -= 0.05;
  }
  else
  {
    dynamic -= 0.01;
  }
  
  dynamic -= 0.015;  
  float yoff_w = dynamic;
  generate_terrain(yoff_w/50);
  
  // generating water each draw()
  for (int y=0; y<rows; y++)
  {
    float xoff_w = 0;
    for (int x=0; x<cols; x++)
    {
      water[x][y] = map(noise(xoff_w, yoff_w), 0, 1, -50, 50);
      xoff_w += 0.2;
    }
    yoff_w += 0.2;
  }
  
  
  
  background(0);
  stroke(120, 20);
  //camera(mouseX, mouseY, (height/2) / tan(PI/6), mouseX, mouseY, 0, 0, 1, 0); 
  //noFill();
  
  
  translate(width/2, height/2+50); //<>//
  rotateX(PI/3);
  translate(-w/2, -h/2);
  
  
  // plotting water
  for (int y=0; y<rows-1; y++)
  {
    beginShape(TRIANGLE_STRIP);
    for (int x=0; x<cols; x++)
    {
      //rect(x*scl, y*scl, scl, scl);
      fill_color = map(water[x][y], -130, 130, 0, 255);
      fill(20, 20, 200, 75);
      vertex(x*scl, y*scl, water[x][y]);
      vertex(x*scl, (y+1)*scl, water[x][y+1]);
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
      fill(terrain_color[0], terrain_color[1], terrain_color[2], terrain_color[3]);
      vertex(x*scl, y*scl, terrain[x][y]);
      vertex(x*scl, (y+1)*scl, terrain[x][y+1]);
    }
    endShape();
  }
  
  cam.beginHUD();
  gui();
  cam.endHUD();
}

float[] terrain_gradient(float height)
{
  float[] terrain_color = {255, 255, 255, 255}; // default snow
  // height between 0 to 1
  
  float[] colorA = {117, 209, 164, 240}; // green
  float[] colorB = {242, 189, 137, 250}; // brown
  
  if (height < 0.7)
  {
  height /= 0.7;
  for (int i=0; i<3; i++)
  {
    terrain_color[i] = colorA[i] + height*(colorB[i]-colorA[i]);
  }
  } 
  if (height < 0.25)
  {
    terrain_color[0] = 20;
    terrain_color[1] = 20;
    terrain_color[2] = 200;
    terrain_color[3] = 100;
  }
  
  return terrain_color;
}


void update(int x, int y)
{
  if (overRect(rectX, rectY, rectSize, rectSize))
  {
    rectOver = true;
  }
  else
  {
    rectOver = false;
  }
}

boolean overRect(int x, int y, int width, int height)
{
  if (mouseX >= x && mouseX <= x+width && mouseY >= y && mouseY <= y+height)
  {
    return true;
  }
  else
  {
    return false;
  }
}

void generate_terrain(float yoff_t)
{
  float min_height = -100;
  float max_height = 250;
  float elev;
  
  float a = 0.06;
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
      elev = pow((e0 + e1 + e2)/1.5, 4);
      //float d = 2*max(abs(nx), abs(ny)); // manhattan
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

void gui()
{
  
}
