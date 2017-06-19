import processing.core.PApplet;
import processing.core.PVector;

import java.util.ArrayList;

/**
 * Created by JoGomes on 08/05/2017.
 */
public class Avatar extends PApplet{
    String username;
    int corR,corG,corB;
    float raio;
    int fuel,ratio;
    double alpha;
    PVector location;
    PVector velocity;
    PApplet parent;
    int time;



    public Avatar(String usr,float r, float x, float y, int a,int b, int c, PApplet p) {
        this.time     = 0;
        this.ratio    = 0;
        this.username = usr;
        this.alpha    = 0.0;
        this.fuel     = 500;
        this.parent   = p;
        this.corR     = a;
        this.corG     = b;
        this.corB     = c;
        this.raio     = r;
        this.location = new PVector(x, y); // posição inicial
        this.velocity = new PVector(0, 0);
    }



    public Avatar(Avatar a){
        this.time     = a.time;
        this.ratio    = a.ratio;
        this.username = a.username;
        this.alpha    = a.alpha;
        this.fuel     = a.fuel;
        this.parent   = a.parent;
        this.corR     = a.corR;
        this.corG     = a.corG;
        this.corB     = a.corB;
        this.raio     = a.raio;
        this.location = a.location;
        this.velocity = a.velocity;
    }

    public void desenha() {
        this.parent.strokeWeight((float) 2.0);
        this.parent.stroke(255,255,255);
        this.parent.fill(this.corR, this.corG, this.corB,50);
        this.parent.ellipse(0, 0, this.raio*2, this.raio*2);
        this.parent.fill(255, 255, 255);
        this.parent.textSize(8);
        this.parent.text(this.username, -this.raio*(float)0.7, 0);
        float x1,x2,x3,y1,y2,y3;
        x1 = 0;
        y1 = this.raio*2;
        x2 = -this.raio/4;
        y2 = raio*(float)1.5;
        x3 = this.raio/4;
        y3 = raio*(float)1.5;
        this.parent.strokeWeight((float) 0.1);
        this.parent.strokeJoin(ROUND);
        this.parent.fill(this.corR, this.corG, this.corB,50);
        this.parent.translate(cos((float) (alpha)),sin((float) (alpha)));
        this.parent.triangle(x1,y1,x2,y2,x3,y3);
    }

    void checkLimite() {
        if (this.location.x > this.parent.width+this.raio-2) {
            this.location.x = -this.raio-2;
        } else if (this.location.x < -(this.raio+2) && this.velocity.x < 0) {
            this.location.x = this.parent.width;
        } else if (this.location.y > this.parent.height+this.raio-2) {
            this.location.y = -this.raio-2;
        } else if (this.location.y < -(this.raio+2) && this.velocity.y < 0) {
            this.location.y = this.parent.height;
        }
    }

    public boolean morrer(Planeta p){
        float minDistance = this.raio+p.raio-2; //o 2 é do stroke

        PVector distanceVect = PVector.sub(p.location, this.location);


        float distanceVectMag = distanceVect.mag();

        if (distanceVectMag < minDistance)
            return true;
        return false;
    }


    public void fuel(){
        this.parent.fill(255, 255, 255);
        this.parent.textSize(15);
        this.parent.text("Fuel: " + this.fuel, 10 ,20);
    }


}
