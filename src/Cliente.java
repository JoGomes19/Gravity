/**
 * Created by JoGomes on 08/05/2017.
 */
import processing.core.PApplet;
import processing.core.PImage;


import java.io.*;
import java.net.*;
import java.util.ArrayList;




public class Cliente  extends PApplet {

    private ArrayList<Planeta> planetas = new ArrayList<Planeta>();
    private ArrayList<Avatar> avatares = new ArrayList<Avatar>();
    private Thread[] thrd = new Thread[2];
    /**
     * Uma Thread para escrever para o servidor,
     * e outra para ler do servidor e desenhar a cena
     * (e outra para contar os segundos para a bateria ir aumentando ???)
     **/

    private PImage img;
    private Avatar b, b2, b3, b4;
    int i, loginX, loginY, registerX, registerY, playX, playY, exitX, exitY, userX, userY, passX, passY;
    int playSize = 210, loginSize = 100, registerSize = 140, exitSize = 37, userSize = 160, passSize = 160;
    int loginColor, registerColor, playColor, exitColor, userColor, passColor;
    int buttonHighlight;
    boolean loginOver = false;
    boolean registerOver = false;
    boolean playOver = false;
    boolean exitOver = false;
    boolean userOver = false;
    boolean passOver = false;
    int menu = 0;
    boolean morto = false;
    private static Socket sck;
    private static BufferedReader in = new BufferedReader(new InputStreamReader(System.in));

    int start;

    static {
        try {
            //println("olaS");
            sck = new Socket("0.0.0.0", 12345);
            //println("olaS");
        } catch (Exception e) {
            println("olaS");
            e.printStackTrace();
            System.exit(0);
        }
    }

    public static void main(String[] args) {
        PApplet.main("Cliente", args);
        try {
            while (true) {
                String a = in.readLine();
                PrintWriter out = new PrintWriter(sck.getOutputStream());
                out.println(a);
                out.flush();
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(0);
        }
    }


    public void settings() {
        size(720, 720);
        loginColor = color(0);
        buttonHighlight = color(51);
        registerColor = color(255);
        loginX = width / 6;
        loginY = height / 6;
        exitX = 15;
        exitY = 10;
        registerX = 4 * width / 6;
        registerY = height / 6;
        playX = 5 * width / 12;
        playY = 4 * height / 6;
        userX = 2 * width / 6;
        userY = height / 6;
        passX = 2 * width / 6;
        passY = 2 * height / 6;
        b = new Avatar("User1", 15, width / 2, height / 2, 204, 102, 0, this);
        b2 = new Avatar("User2", 15, width / 2, height / 2, 141, 236, 120, this);
        b3 = new Avatar("User3", 15, random(20, width - 20), random(20, height - 20), 170, 126, 120, this);
        b4 = new Avatar("User4", 15, random(20, width - 20), random(20, height - 20), 123, 206, 20, this);
        avatares.add(b);
        //avatares.add(b2);
        //avatares.add(b3);
        //avatares.add(b4);
        for (int i = 0; i < 6; i++) {
            int tam = (int) random(25, 50);
            float px = random(tam, width - tam);
            float py = random(tam, height - tam);
            float vel = random(0, 1);
            planetas.add(new Planeta("Planeta"+i, tam, px, py, vel, vel, (int) random(255), (int) random(255), (int) random(255), this));
        }
    }


    public void setup() {
        img = loadImage("grid.png");
        start = millis();
    }

    public void draw() {
        background(img);
        if (menu != 3) menu();
        if (menu == 3) {


            pushMatrix();
            translate(b.location.x, b.location.y);
            rotate((float) b.alpha - PI / 2);
            b.desenha();
            b.velocity.x = b.ratio * cos((float) b.alpha);
            b.velocity.y = b.ratio * sin((float) b.alpha);

            b.location.add(b.velocity);
            b.checkLimite();

            for (Planeta p : planetas) {
                if (b.morrer(p)) {
                    b.ratio = 0;
                    morto = true;
                    for (Planeta p1 : planetas) {
                        p1.velocity.x = 0;
                        p1.velocity.y = 0;
                    }
                }
            }
            popMatrix();


            pushMatrix();
            for (Planeta p : planetas) {
                p.checkLimite();
                p.location.add(p.velocity);
                p.desenha();
            }
            popMatrix();

            table(avatares);
            b.fuel();
        }
    }

    public void keyPressed() {
        if (key == CODED) {
            if (keyCode == UP) {
                try {
                    PrintWriter out = new PrintWriter(sck.getOutputStream());
                    out.println("UP");
                    out.flush();
                    if (b.fuel > 0) {
                        b.ratio += 1;
                        //println(b.alpha);
                        if (b.ratio > 0)
                            b.fuel -= 1;
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            } else if (keyCode == DOWN) {
                try {
                    PrintWriter out = new PrintWriter(sck.getOutputStream());
                    out.println("DOWN");
                    out.flush();
                    if (b.fuel > 0) {
                        b.ratio -= 1;
                        //println(b.alpha);
                        if (b.ratio > 0)
                            b.fuel -= 1;
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            } else if (keyCode == RIGHT) {
                try {
                    PrintWriter out = new PrintWriter(sck.getOutputStream());
                    out.println("RIGHT");
                    out.flush();
                    if (b.fuel > 0) {
                        b.alpha += 0.2;
                        //println(b.alpha);
                        b.fuel--;
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            } else if (keyCode == LEFT) {
                try {
                    PrintWriter out = new PrintWriter(sck.getOutputStream());
                    out.println("LEFT");
                    out.flush();
                    if (b.fuel > 0) {
                        b.alpha -= 0.2;
                        //println(b.alpha);
                        b.fuel--;
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }


    public void menu() {
        update(mouseX, mouseY);
        switch (menu) {
            case 0:
                if (loginOver) {
                    fill(buttonHighlight);
                } else {
                    fill(loginColor);
                }
                stroke(255);
                rect(loginX, loginY, loginSize, 90);
                textSize(30);
                fill(255, 255, 255);
                text("Login", loginX + 10, loginY + 50);
                if (registerOver) {
                    fill(buttonHighlight);
                } else {
                    fill(loginColor);
                }
                stroke(255);
                rect(registerX, registerY, registerSize, 90);
                fill(255, 255, 255);
                text("Register", registerX + 10, registerY + 50);
                if (playOver) {
                    fill(buttonHighlight);
                } else {
                    fill(playColor);
                }
                stroke(255);
                rect(playX, playY, playSize, 90);
                textSize(30);
                fill(255, 255, 255);
                text("Offline Guest", playX + 10, playY + 50);
                break;
            case 1:
                try {
                    BufferedReader in = new BufferedReader(new InputStreamReader(sck.getInputStream()));
                    String res = in.readLine();
                    println(res);
                    if (res.equals("Welcome back!")) {
                        menu = 3;
                        b.time = 0;
                        start = millis();
                    }
                    else
                        menu = 0;
                } catch (IOException e) {
                    e.printStackTrace();
                }

                break;
            case 2:
                try {
                    BufferedReader in = new BufferedReader(new InputStreamReader(sck.getInputStream()));
                    String res = in.readLine();
                    println(res);
                } catch (IOException e) {
                    e.printStackTrace();
                }
                menu = 0;

                break;
            case 4:
                try {
                    BufferedReader in = new BufferedReader(new InputStreamReader(sck.getInputStream()));
                    String res = in.readLine();
                    println(res);
                } catch (IOException e) {
                    e.printStackTrace();
                }
                menu = 0;

                break;
            default:
                break;
        }
        /** EXIT **/
        if (exitOver) {
            fill(buttonHighlight);
        } else {
            fill(exitColor);
        }

        stroke(255);
        rect(exitX, exitY, exitSize, 20);
        textSize(15);
        fill(255, 255, 255);
        text("Exit", exitX + 5, exitY + 15);
    }

    void update(int x, int y) {
        if (registerRect(registerX, registerY, registerSize, 90)) {
            loginOver = false;
            registerOver = true;
            playOver = false;
            exitOver = false;
            userOver = false;
        } else if (loginRect(loginX, loginY, loginSize, 90)) {
            loginOver = true;
            registerOver = false;
            playOver = false;
            exitOver = false;
            userOver = false;
        }
        else if (playRect(playX, playY, playSize, 90)) {
            loginOver = false;
            registerOver = false;
            playOver = true;
            exitOver = false;
            userOver = false;
        } else if (exitRect(exitX, exitY, exitSize, 20)) {
            loginOver = false;
            registerOver = false;
            playOver = false;
            exitOver = true;
            userOver = false;
        } else if (userRect(userX, userY, userSize, 90)) {
            loginOver = false;
            registerOver = false;
            playOver = false;
            exitOver = false;
            userOver = true;
        } else if (passRect(passX, passY, passSize, 90)) {
            loginOver = true;
            registerOver = false;
            playOver = false;
            exitOver = false;
            userOver = false;
            passOver = true;
        } else {
            registerOver = loginOver = playOver = exitOver = userOver = passOver = false;
        }
    }

    boolean playRect(int x, int y, int width, int height) {
        if (mouseX >= x && mouseX <= x + width &&
                mouseY >= y && mouseY <= y + height) {
            return true;
        } else {
            return false;
        }
    }

    boolean loginRect(int x, int y, int width, int height) {
        if (mouseX >= x && mouseX <= x + width &&
                mouseY >= y && mouseY <= y + height) {
            return true;
        } else {
            return false;
        }
    }

    boolean registerRect(int x, int y, int w, int h) {
        if (mouseX >= x && mouseX <= x + w &&
                mouseY >= y && mouseY <= y + h) {
            return true;
        } else {
            return false;
        }
    }


    boolean exitRect(int x, int y, int w, int h) {
        if (mouseX >= x && mouseX <= x + w &&
                mouseY >= y && mouseY <= y + h) {
            return true;
        } else {
            return false;
        }
    }

    boolean userRect(int x, int y, int w, int h) {
        if (mouseX >= x && mouseX <= x + w &&
                mouseY >= y && mouseY <= y + h) {
            return true;
        } else {
            return false;
        }
    }

    boolean passRect(int x, int y, int width, int height) {
        if (mouseX >= x && mouseX <= x + width &&
                mouseY >= y && mouseY <= y + height) {
            return true;
        } else {
            return false;
        }
    }

    public void mousePressed() {
        if (loginOver) {
            menu = 1;
            try {
                PrintWriter out = new PrintWriter(sck.getOutputStream());
                println("1");
                out.print("1 ");
                out.flush();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        if (registerOver) {
            menu = 2;
            try {
                PrintWriter out = new PrintWriter(sck.getOutputStream());
                System.out.println("2");
                out.print("2 ");
                out.flush();
                //leitura.randomMessage();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        if (playOver) {
            menu = 3;
            for (Avatar av : avatares) {
                av.time = 0;
                start = millis();
            }
        }
        if (exitOver) {
            menu = 4;
            try {
                PrintWriter out = new PrintWriter(sck.getOutputStream());
                println("4");
                out.print("4 ");
                out.flush();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }


    void table(ArrayList<Avatar> av) {

        fill(255, 255, 255);
        textSize(30);
        text("Leaderboard:\n", width - 213, 40);
        textSize(30);
        int y1 = 60, i = 1;
        for (Avatar a : av) {
            fill(255, 255, 255);
            if (a == b) {
                fill(179, 247, 154);
            } else
                fill(255, 255, 255);
            textSize(15);
            text(i + ".  " + a.username + ": ", width - 210, y1);
            if(!morto)
                a.time =  millis()-start;
            else{
                fill(255, 255, 255);
                textSize(30);
                text("Game Over", width/2-70, height/2-2);
                textSize(15);
            }
            text(a.time/1000, a.parent.width - 130, y1);
            //text("("+ a.fuel+")", a.parent.width - 100, y1);
            y1 += 20;
            i++;
        }
    }

}
