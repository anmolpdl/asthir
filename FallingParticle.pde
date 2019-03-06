class FallingParticle
{
  float x, y, speed;
  color c;
  FallingParticle()
  {
    x = random(width);
    y = random(-500, 500); 
  }
  
  void update()
  {
    y += speed;
    speed += 0.05;
    
    if (y > height)
    {
      y = random(-300, 0);
      
    }
  }
}

class Raindrop extends FallingParticle
{
  float len;  
  
  Raindrop()
  {
    super();
    len = random(10, 30);
    c = color(random(100), random(100), random(200, 255));
    speed = random(5, 10);
  }
  
  void update()
  {
    super.update();
    speed = random(5, 10);
  }
  
  void display()
  {
    fill(c);
    noStroke();
    rect(x, y, len/10, len);
  }
}

class Snowflake extends FallingParticle
{
  float size;
  float direction;
  
  Snowflake()
  {
    super();
    size = random(2, 10);
    c = color(255, 255, 255);
    speed = random(1, 5);
    direction = random(-1, 1);
  }
  
  void update()
  {
    super.update();
    x += direction;
    speed = random(1, 5);
  }
  
  void display()
  {
    fill(c);
    noStroke();
    ellipse(x, y, size, size);
  }
  
}
