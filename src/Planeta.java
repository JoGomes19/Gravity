import processing.core.PApplet;
import processing.core.PVector;
import java.util.concurrent.*;
import java.util.concurrent.locks.ReentrantLock;
import java.util.concurrent.locks.Lock;
/**
 * Created by JoGomes on 08/05/2017.
 */
public class Planeta extends PApplet{
    int corR,corG,corB;
    float raio, m;
    String nome;
    PVector location;
    PVector velocity;
    PApplet parent;


    public Planeta(String n,int r, float px, float py,float vx, float vy, int a,int b, int c, PApplet p) {
        this.nome = n;
        this.parent = p;
        this.corR = a;
        this.corG = b;
        this.corB = c;
        this.raio = r;
        this.m = raio*1;
        this.location = new PVector(px, py); // posição inicial
        this.velocity = new PVector(vx, vy);
    }


    public Planeta(Planeta p){
        this.nome = p.nome;
        this.parent = p.parent;
        this.corR = p.corR;
        this.corG = p.corG;
        this.corB = p.corB;
        this.raio = p.raio;
        this.m = p.m;
        this.location = p.location;
        this.velocity = p.velocity;
    }

    public void desenha() {
        this.parent.noStroke();
        this.parent.fill(this.corR, this.corG, this.corB);
        this.parent.ellipse(this.location.x, this.location.y, this.raio*2, this.raio*2);
    }

    void checkLimite() {
        if (this.location.x > this.parent.width-this.raio) {
            this.location.x = this.parent.width-this.raio;
            velocity.x *= -1;
        } else if (this.location.x <= this.raio) {
            this.location.x = this.raio;
            velocity.x *= -1;
        } else if (this.location.y > this.parent.height-this.raio) {
            this.location.y = this.parent.height-this.raio;
            velocity.y *= -1;
        } else if (this.location.y <= this.raio) {
            this.location.y = this.raio;
            velocity.y *= -1;
        }
    }

}
