import controlP5.*;
import java.util.*;
import java.text.*;

State program_state;

//for sliders
ControlP5 cp5;
Slider speed_slider;

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
        scl = 10; //pixel density
        watervol = 2;

        //position of camera
        cameraposX = w/2;
        cameraposZ = h/2;
        cameraposY = 650; //works only for w=h=2000

        cols = w/scl;
        rows = h/scl;

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
        cp5.addSlider("a").setPosition(4*width/5, 1.5*height/60).setSize(height/4, width/68).setRange(0., 0.8).setValue(a).setCaptionLabel("vertical offset");
        cp5.addSlider("b").setPosition(4*width/5, 3.5*height/60).setSize(height/4, width/68).setRange(0.5, 0.8).setValue(b).setCaptionLabel("edge offset");
        cp5.addSlider("c").setPosition(4*width/5, 5.5*height/60).setSize(height/4, width/68).setRange(0., 3.0).setValue(c).setCaptionLabel("edge exponent");
        cp5.addSlider("terrain_octave").setPosition(4*width/5, 7.5*height/60).setSize(height/4, width/68).setRange(1, 10).setValue(terrain_octave).setCaptionLabel("octaves");
        //cp5.addSlider("fov").setPosition(width/50, 19*height/30).setSize(width/60, height/3).setRange(PI/4, PI/1.1); //RIP TB
}

void draw() {
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
                        dynamic -=speed;
                        flow_in_sea = dynamic;
                        flow_on_land = dynamic/100;

                        background(135, 206, 250);

                        pushMatrix();
                        translate(w/2,h/2);
                        rotateX(PI/2);
                        translate(-w/2,-h/2);

                        dynamic_lighting();
                        generate_noise();
                        render_terrain();
                        render_water();
                        
                        // making a box
                        //int x0 = cols/2;
                        //int y0 = rows/2;
                        //float z0 = land_factor*terrain[x0][y0]+cliff;
                        
                        //translate((x0+rows/2)*scl, (y0+cols/2)*scl, z0);
                        //fill(255);
                        //box(30);
                        //translate(-(x0+rows/2)*scl, -(y0+cols/2)*scl, -z0);

                        
                        popMatrix();
                        hud();
                        custompan();

                        if (int(random(200)) == 7) {
                                program_state = State.MAIN_RAINING;
                                rain_timer = 150+int(random(300));
                        }
                break;
                case MAIN_RAINING:
                        dynamic -=speed;
                        flow_in_sea = 2*dynamic;
                        flow_on_land = dynamic/100;

                        background(125, 178, 250);

                        pushMatrix();
                        translate(w/2,h/2);
                        rotateX(PI/2);
                        translate(-w/2,-h/2);

                        dynamic_lighting();
                        generate_noise();
                        render_terrain();
                        render_water();

                        popMatrix();
                        hud();
                        custompan();


                        int r2 = int(random(50));
                        if (rain_timer == 0) {
                                program_state = State.MAIN_NORMAL; 
                        }
                        rain_timer--;
                        if (((int(random(20)) == 7)&&(a > 0.4))||(a > 0.7)) {
                                program_state = State.MAIN_SNOWING;
                        }
                break;
                case MAIN_SNOWING:
                        dynamic -=speed;
                        flow_in_sea = dynamic;
                        flow_on_land = dynamic/100;

                        background(135, 206, 250);

                        pushMatrix();
                        translate(w/2,h/2);
                        rotateX(PI/2);
                        translate(-w/2,-h/2);

                        dynamic_lighting();
                        generate_noise();
                        render_terrain();
                        render_water();

                        popMatrix();
                        hud();
                        custompan();

                        if (rain_timer == 0) {
                                program_state = State.MAIN_NORMAL; 
                        }
                        if (a < 0.25) {
                                program_state = State.MAIN_RAINING;
                        }
                        rain_timer--;
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
                        //float dist = sqrt(pow(cols/2-x,2)+pow(rows/2-y,2));
                        ////mapping upto sqrt(2) instead of 1 for island illusion
                        //float d = map(dist,0,sqrt(cols/2*cols/2+rows/2*rows/2),0,sqrt(2));
                        //float dist1 = sqrt(pow(cols/2-x,2)+pow(rows/2-y-1,2));
                        //float d1 = map(dist1,0,sqrt(cols/2*cols/2+rows/2*rows/2),0,sqrt(2));
                        //float e =(terrain[x][y] + a)*(1 - b*pow(d,c));
                        //float e1 =(terrain[x][y+1] + a)* (1- b*pow(d1,c));

                        //land factor is 500
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

        // guisetup(); deprecated in favor of hud
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
        image(save_img,20,20,100,100);
        ((PGraphics3D)g).camera = currCameraMatrix;
        hint(ENABLE_DEPTH_TEST); 
        //end HUD
        popMatrix();
}

void dynamic_lighting() {
        ambientLight(172, 136, 111);
        directionalLight(50, 50, 50, 0, 0, -1);
        pointLight(150, 150, 150, w/2, h/2, 100);
}

void generate_noise() {
        //land
        //int terrain_octave = 10;
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
        // height between 0 to 1

        float[] colorA = {0, 255, 0, 255}; // green
        float[] colorB = {242, 189, 137, 255}; // brown
        float[] sand = {224,205,235,255};
        if (height < 0.7 && height >0.3) {
                height /= 0.7;
                for (int i=0; i<3; i++) {
                        terrain_color[i] = colorA[i] + height*(colorB[i]-colorA[i]);
                }
        }
        else if (height<0.3) {
                height /= 0.3;
                for (int i=0; i<3; i++) {
                        terrain_color[i] = sand[i] + height*(colorB[i]-sand[i]);
                }
        } 

        return terrain_color;
}

void custompan() {
        if (cameraposY>300) {
                camera(cameraposX,cameraposY,cameraposZ,cameraposX+100,cameraposY,cameraposZ,0,1,0);

                //defining the perspective projection parameters

                float cameraZ = (height/2.0) / tan(fov/2.0);

                //projection
                perspective(fov, float(width)/float(height), cameraZ/10.0, cameraZ*10.0);
                cameraposY-=speed;
        }
        else {
                beginCamera();
                translate(w,cameraposY,h/2);
                rotateY(-speed/100);
                translate(-w,-cameraposY,-h/2);
                endCamera();
        }
        /*
        note: source code for projection(perspective):
        for later reference, can be modified along with frustum
        (that has the actual projection matrix)
        to create other projections*/

        /*@Override
        //fov = vertical field of view in degrees
        public void perspective(float fov, float aspect, float zNear, float zFar)  {
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
}

void keyPressed() {
        if (program_state == State.START) {
                // if (at_start) {
                //         at_start = false;
                // }
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
                                //if (!at_start) {
                                //at_start = true;
                                program_state = State.START;
                                cp5.remove("speed");
                                popMatrix();
                                setup();
                                //}
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
                                datafile.println("a:"+str(a)+",b:"+str(b)+",c:"+str(c));
                                datafile.flush();
                                datafile.close();
                        break;
                }
        }
}
