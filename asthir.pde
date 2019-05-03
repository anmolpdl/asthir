import controlP5.*;
import java.util.*;
import java.text.*;

State program_state;

//for sliders and fps
ControlP5 cp5;
Slider speed_slider;
Textlabel fps;

PImage start_screen, save_img;
//for img parameters
PrintWriter datafile;


//start screen booleans
boolean at_start, startflag;

//width, height, pixel density, watervol
int w, h, scl, cols, rows, watervol;

float[][] terrain, water;

float flow_on_land, flow_in_sea; //water flows slower on land than in sea
float cameraposX, cameraposY, cameraposZ;
float dynamic, speed, fov; // dynamic = level of dynamicness of terrain, use fov = Pi/1.4-Pi/1.6 for fisheye
float light_angle;

//constants for island creation
//a pushes everything up, b pushes edges down, c controls the quickness of dropoff, set a&b to 0 for default
float a, b, c;

//terrain adjustment factors
int land_factor, water_factor, sea_level, cliff, terrain_octave;

//for rain
int rain_timer;
Raindrop rain[];
Snowflake snow[];

//for temporarily storing the 3D matrix before rendering GUI
PMatrix3D currCameraMatrix;
PGraphics3D g3;

void setup() {
        Perlin.setup(this, 512);
        //cam = new PeasyCam(this, w/2, h/2, 1000, 0);
        //cam.setMaximumDistance(3000);

        fullScreen(P3D);
        smooth(4); // anti aliasing

        w =2000;
        h =2000;
        scl = 20; //pixel density
        watervol = 2;

        //position of camera
        cameraposX = w/2;
        cameraposZ = h/2;
        cameraposY = 650; //works only for w=h=2000

        cols = w/scl;
        rows = h/scl;
        
        //starting light state- 0=morning, PI/2=noon, PI=evening,3PI/2=night
        light_angle = HALF_PI;

        dynamic = 0;
        speed = 0.01;
        fov = PI/3; // use Pi/1.4-Pi/1.6 for fisheye

        a = 0.06;
        b = 0.6;
        c = 1;

        land_factor = 700;
        water_factor = 75;
        sea_level = 200;
        cliff = 25;
        terrain_octave = 4;

        //dynam alloc memory
        terrain = new float[cols][rows];
        water = new float [watervol*cols][watervol*rows];
        save_img = createImage(cols, rows, RGB);

        rain = new Raindrop[500];
        for (int i=0;i<500;i++) {
                rain[i] = new Raindrop();
        }
        snow = new Snowflake[200];
        for (int i=0;i<200;i++) {
                snow[i] = new Snowflake();
        }

        //start screen
        start_screen = loadImage("./resources/start_screen.jpg");
        at_start = true;
        startflag = false;
        program_state = State.START;

        //setting up sliders
        cp5 = new ControlP5(this);
        fps=cp5.addFrameRate().setInterval(10).setPosition(width/70,0).setColor(255);
        cp5.addSlider("a").setPosition(4*width/5, 1.5*height/60).setSize(height/4, width/68).setRange(0., 0.8).setValue(a).setCaptionLabel("vertical offset");
        cp5.addSlider("b").setPosition(4*width/5, 3.5*height/60).setSize(height/4, width/68).setRange(0.5, 0.8).setValue(b).setCaptionLabel("edge offset");
        cp5.addSlider("c").setPosition(4*width/5, 5.5*height/60).setSize(height/4, width/68).setRange(0., 3.0).setValue(c).setCaptionLabel("edge exponent");
        cp5.addSlider("terrain_octave").setPosition(4*width/5, 7.5*height/60).setSize(height/4, width/68).setRange(1, 10).setValue(terrain_octave).setCaptionLabel("octaves");
        
}

void draw() {
  //note: renderscene() does what you think it does
        switch(program_state) {
                case START:
                        image(start_screen, 0, 0, width, height);
                        fill(181, 101, 29, 200);
                        textSize(width/10);
                        textAlign(RIGHT);
                        text("Asthir", width/3, 3*height/5);
                        textSize(width/40);
                        text("Press Enter", width/5, 2*height/3);
                        textSize(width/80);
                        fill(255, 255, 255, 255);
                        textAlign(LEFT);
                        text("Parameters:", 4*width/5, height/50);
                        for (int i=0; i<200; i++) {
                                snow[i].display();
                                snow[i].update();
                        }
                break;
                case MAIN_NORMAL:
                        // normal code
                        if (int(random(300)) == 7) {
                                //program_state = State.MAIN_RAINING;
                                rain_timer = 100+int(random(200));
                        }
                        renderscene();
                break;
                case MAIN_RAINING:
                        int r2 = int(random(50));
                        if (rain_timer == 0) {
                                program_state = State.MAIN_NORMAL; 
                        }
                        rain_timer--;
                        if (((int(random(20)) == 7)&&(a > 0.4))||(a > 0.7)) {
                                program_state = State.MAIN_SNOWING;
                        }
                        renderscene();
                break;
                case MAIN_SNOWING:
                        if (rain_timer == 0) {
                                program_state = State.MAIN_NORMAL; 
                        }
                        if (a < 0.25) {
                                //program_state = State.MAIN_RAINING;
                        }
                        rain_timer--;
                        renderscene();
                break;
        }     
}

void render_terrain() {    
        save_img.loadPixels();
        //draw the actual thing
        //land
        for (int y=0; y<rows-1; y++) {
                beginShape(TRIANGLE_STRIP);
                for (int x=0;x<cols; x++) {
                        float[] terrain_color = terrain_gradient(map(land_factor*terrain[x][y]+cliff, 0, land_factor+cliff, 0, 1));

                        // saving to pixels array
                        save_img.pixels[y*cols+x] = color(terrain_color[0], terrain_color[1], terrain_color[2]);
                        save_img.pixels[(y+1)*cols+x] = color(terrain_color[0], terrain_color[1], terrain_color[2]);
                        fill(terrain_color[0], terrain_color[1], terrain_color[2], 255);
                        noStroke();
                        vertex((x+rows/2)*scl, (y+cols/2)*scl, land_factor*terrain[x][y]+cliff);
                        vertex((x+rows/2)*scl, (y+cols/2+1)*scl, land_factor*terrain[x][y+1]+cliff);
                }
                endShape();
        }
        save_img.updatePixels();
}

void render_water() {
        //water
        for (int y=0; y<watervol*rows-1; y++) {
                beginShape(TRIANGLE_STRIP);
                for (int x=0;x<watervol*cols; x++) {
                        fill(20, 20, 200, 75);
                        noStroke();
                        vertex(x*scl, y*scl, water_factor*water[x][y]+sea_level);
                        vertex(x*scl, (y+1)*scl, water_factor*water[x][y+1]+sea_level);
                }
                endShape();
        }
}

void hud() {
        pushMatrix();
        //beginHUD

        if (!startflag) {
                pushMatrix();
                speed_slider = cp5.addSlider("speed").setPosition(width/50, 19*height/30).setSize(width/60, height/3).setRange(0., 2.0);
                speed_slider.setValue(speed);

                //so sliders don't get drawn automatically in 3D space and only on the static camera()
                cp5.setAutoDraw(false);
                startflag =true;
        }

        hint(DISABLE_DEPTH_TEST);
        PMatrix3D currCameraMatrix = new PMatrix3D(((PGraphics3D)g).camera);
        camera();
        noLights();
        if (program_state == State.MAIN_RAINING) {
                for (int i=0; i<500; i++) {
                        rain[i].display();
                        rain[i].update();
                }
        }
        else if (program_state == State.MAIN_SNOWING) {
                for (int i=0; i<200; i++) {
                        snow[i].display();
                        snow[i].update();
                } 
        }

        cp5.draw();
        image(save_img,width/70,height/40,100,100);
        ((PGraphics3D)g).camera = currCameraMatrix;
        hint(ENABLE_DEPTH_TEST); 
        //end HUD
        popMatrix();
}

void dynamic_lighting(float angle) {
         //the sun (sphere) revolves arounf the canvas
         //current position of sun
        float light_position = angle % TWO_PI;
        //intensity
        float light_alpha;
  
        //Sun starts on horizon and peaks at HALF_PI
        //Lowest at 3*Half_pi 
        if (light_position>=3*HALF_PI)
                light_alpha = map(abs(light_position), 3*HALF_PI, TWO_PI, 25, 50);
        else if(light_position<=HALF_PI)
                light_alpha = map(abs(light_position), 0, HALF_PI, 50, 180);
        else
                light_alpha = map(abs(light_position), HALF_PI, 3*HALF_PI, 180,25);
                
        background(light_alpha, light_alpha, light_alpha);
        
        pushMatrix();
        translate(w,h,0);
        rotateX(-angle);
        
        //*10 so the sun(sphere) is at a faraway distance
        translate(0,-10*h,0);
        fill(255,255,255);
        sphere(200);
        
        //there's some ambient light(+25) even at night, ambient light is dimmer than usual light by a factor of 10 (/10)
        ambientLight(light_alpha/10+25,light_alpha/10+25,light_alpha/10+25);
        
        //*1.4 to make light look yellowish
        pointLight(light_alpha*1.4, light_alpha*1.4, light_alpha,0,0,0);
        //directionalLight(light_alpha*1.4, light_alpha*1.4, light_alpha,0,1,0);
        
        popMatrix();
}

void generate_noise() {
        //land
        float terrain_persistence = 0.35;
        for (int y = 0; y < rows; y++) {
                for (int x = 0; x < cols; x++) {      
                float nx = (float)scl/20*(float)x/12,ny = (float)scl/20*(float)y/12 ;
                float e = Perlin.get_OctaveNoise(nx+Perlin.get_Noise(flow_on_land),
                                                        ny+Perlin.get_Noise(flow_on_land),
                                                        terrain_octave,
                                                        terrain_persistence);
                float dist = sqrt(pow(cols/2-x,2)+pow(rows/2-y,2));
                //mapping upto sqrt(2) instead of 1 for island illusion
                float d = map(dist,0,sqrt(cols/2*cols/2+rows/2*rows/2),0,sqrt(2));
                terrain[x][y] =(e + a)*(1 - b*pow(d, c));
                }
        }

        //water
        for (int y = 0; y < watervol*rows; y++) {
                for (int x = 0; x < watervol*cols; x++) {      
                        float nx = float(scl)/20*(float)x/5,ny = float(scl)/20*(float)y/5 ;
                        if ((y<cols/2+cliff || y>3*cols/2-cliff) ||(x<rows/2+cliff ||x>3*rows/2-cliff))
                                water[x][y] = Perlin.get_Noise(nx, ny+flow_in_sea);
                        else
                                water[x][y] = Perlin.get_Noise(nx, ny+flow_on_land);
                }
        }
}

float [] terrain_gradient(float height) {
        float[] terrain_color = {255, 255, 255, 255}; // default snow
        float[] colorA = {0, 255, 0, 255}; // green
        float[] colorB = {242, 189, 137, 255}; // brown
        float[] sand = {224,205,235,255}; //sand color
        if (height < 0.7 && height >0.35) {
                height /= 0.7;
                for (int i=0; i<3; i++) {
                        terrain_color[i] = colorA[i] + height*(colorB[i]-colorA[i]);
                }
        }
        else if (height<0.35) {
                height /= 0.35;
                for (int i=0; i<3; i++) {
                        terrain_color[i] = sand[i] + height*(colorB[i]-sand[i]);
                }
        } 

        return terrain_color;
}
void renderscene(){
        dynamic -=speed;
        flow_in_sea = dynamic;
        flow_on_land = dynamic/100;
        pushMatrix();
        translate(w/2,h/2);
        rotateX(PI/2);
        translate(-w/2,-h/2);

        dynamic_lighting(light_angle);
        generate_noise();
        render_terrain();
        render_water();
        light_angle+=speed/100;
        popMatrix();
        hud();
        custompan();
}

void custompan() {
        if (cameraposY>300) {
                camera(cameraposX,cameraposY,cameraposZ,
                        cameraposX+1,cameraposY,cameraposZ,
                        0,1,0);
                //defining the perspective projection parameters
                float cameraZ = (height/2.0) / tan(fov/2.0);

                //projection
                perspective(fov, float(width)/float(height), cameraZ/10.0, cameraZ*100.0);
                cameraposY-=speed;
        }
        else {
                beginCamera();
                translate(w,cameraposY,h/2);
                rotateY(-speed/100);
                translate(-w,-cameraposY,-h/2);
                endCamera();
        }
}

void keyPressed() {
        if (program_state == State.START) {
                if (keyCode == ENTER) {
                        program_state = State.MAIN_NORMAL;
                }
        }
        else {
                switch(key) {
                        case '0':
                                speed = 0;
                                speed_slider.setValue(speed);
                        break;
                        case '1':
                        case '!':
                                speed = 0.01;
                                speed_slider.setValue(speed);
                        break;
                        case '2':
                        case '@':
                                speed = 0.025;
                                speed_slider.setValue(speed);
                        break;
                        case '3':
                        case '#':
                                speed = 0.05;
                                speed_slider.setValue(speed);
                        break;
                        case '4':
                        case '$':
                                speed = 0.1;
                                speed_slider.setValue(speed);
                        break;
                        case '5':
                        case '%':
                                speed = 0.25;
                                speed_slider.setValue(speed);
                        break;
                        case '6':
                        case '^':
                                speed = 0.5;
                                speed_slider.setValue(speed);
                        break;
                        case '7':
                        case '&':
                                speed = 2;
                                speed_slider.setValue(speed);
                        break;
                        default:

                        break;
                        case 'r':
                        case 'R':
                                program_state = State.START;
                                cp5.remove("speed");
                                popMatrix();
                                setup();
                        break;
                        case 's':
                        case 'S':
                                DateFormat name_format = new SimpleDateFormat("yyyy-MM-dd@HH_mm_ss");
                                Date d = new Date();
                                String file_name = name_format.format(d);

                                save_img.updatePixels();
                                saveFrame("./output/SCRNSHT"+file_name+".jpg");
                                save_img.save("./output/MAP"+file_name+".jpg");
                                datafile  = createWriter("./output/DATA"+file_name+".txt");
                                //to store noise data
                                datafile.println("a:"+str(a)+",b:"+str(b)+",c:"+str(c)+
                                ",scl:"+str(scl)+",fps:"+str(frameRate));
                                datafile.flush();
                                datafile.close();
                        break;
                }
        }
}
