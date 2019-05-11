/*-------------------------------------------------------------------------------
Name:        Remote Control Transsmitter PC Version 
Purpose:     Easy checking of methods on a PC without multitouch  
             Using as the baseline for a Android App   
Author:      Bernd Hinze

Created:     11.05.2019
Copyright:   (c) Bernd Hinze 2019
Licence:     MIT see https://opensource.org/licenses/MIT
 ------------------------------------------------------------------------------
*/
import hypermedia.net.*;
UDP udp;
boolean SIM = false;
// Start adaptation required
Lever L1; 
LeverT L2;
Trim T1;
Trim T2;
SwitchApp S1;
Switch S2;
Indicator ICom;
// End adaptation 

String ip       = "";  // the remote IP address
int port        = 6100;    // the destination port
int tms_received = millis();
int tms_received_tout = 5 * 1000; // 20s
boolean ip_received = false; 
String ID = "";            // receiver ID 
String [] CodeTable  =  {"0","1","2", "3", "4", "5", "6","7", "8", "9", ":", ";", "<", "=",">","?"}; 


void setup()
{
  defaultPosL1 = 50;
  size(800,400);
  orientation(LANDSCAPE); 
  //fullScreen();
  background (#63aad0);
  // Start adaptation required
  if (SIM)
  {
    ip  = "192.168.1.2";  // the remote IP address
    ip_received = true; 
  }
  L1 = new Lever (int(width*0.25), int(height*0.15),  int(height*0.85), int (50), 0);
  L2 = new LeverT (int(height*0.5), int(width*0.5), int(width*0.9), int (50),  4);
  T1 = new Trim(int(width * 0.09), int(height * 0.5), "P", 0);
  T2 = new Trim(int(width * 0.7), int(height * 0.8), "L", 4);
  S1 = new SwitchApp(int(height * 0.04), int(width * 0.5), int(height * 0.15), 15, 100); 
  S2 = new Switch(int(height * 0.04), int(width * 0.6), int(height * 0.15), 3, 255);
  ICom = new Indicator(ID, "No Device" , 0.95, 0.10);
  // End adaptation 
  udp = new UDP (this, 6000);
  udp.listen( true );
}
  

void draw() 
{
  background (#63aad0);
  // Start adaptation required
  L1.display();
  L2.display();
  T1.display();
  T2.display();
  S1.display();
  S2.display();
  // End Adaptation 
  ICom.display(ip_received);
  if (ip_received == true){
    try{
      // Start adaptation required
      udp.send(L1.getVal(L1.py) + L2.getVal(L2.px), ip, port);
      // End Adaptation required
      println(L1.getVal(L1.py) + L2.getVal(L2.px));     
    }
    catch (Exception e){}
  }
  if (SIM ==false){
    if ((millis() - tms_received) > tms_received_tout){
      ip_received = false;
    }
  }
}


void mousePressed()
{ 
  // Start adaptation required  
  if (T1.overT() &&  (ip_received == true))
  {  
    if (udp.send(T1.getSval(), ip, port) == false)
    {
      ip_received = false;
    }
  }
  if (T2.overT() &&  (ip_received == true))
  {
    if (udp.send(T2.getSval(), ip, port) == false)
    {
      ip_received = false;
    }
  }
  if (S1.overS() &&  (ip_received == true))
  {
    if (udp.send(S1.getSval(), ip, port) == false)
    {
      ip_received = false;
    }
  }
  if (S2.overS() &&  (ip_received == true))
  {
    if (udp.send(S2.getSval(), ip, port) == false)
    {
      ip_received = false;
    }
  }
  // End adaptation 
}

/* -------------------------------------------------------------------------
   The function draws the current state of the connction and the receiver ID 
   on the right corner of the screen.
----------------------------------------------------------------------------   
*/
class Indicator 
{
  int tx, ty, ex, ey, ed;
  String gr, rd;
  Indicator(String green, String red , float x , float y)
  {
    ex = int(width * x);
    ey = int(height * y);
    ed = int(height * 0.05);
    tx = int(width * (x - 0.03));
    ty = int(height * (y + 0.015)); 
    gr = green;
    rd = red;
  }

  void display(boolean state)
  {
    textAlign(RIGHT);
    if (state == true){
        fill(#04C602);
        ellipse(ex, ey, ed, ed);  
        fill(80);
        text(gr, tx, ty);
    } else {
        fill(#FF0000);
        ellipse(ex, ey, ed, ed);
        fill(80);
        text(rd, tx, ty);
    }
  }
}


/* ----------------------------------------------------------------------------------
   That is the default method of the UDP library for listening. The receiver transmits 
   cyclic every second the following string decoded to the Application: "ID@IP". 
   Example "RC#001@192.168.43.3". It will be splitted and checked whether it is an IP 
   from an local network. The variable 'ip_received' and the timestamp is set.
------------------------------------------------------------------------------------  
*/
void receive(byte[] data)
{  
  String message = new String( data );
  String[] parts = split(message, "@");
  ID = parts[0]; 
  String[] ip_parts = split(parts[1], ".");
  // checking wether it is probably a IP adress
  if ((int(ip_parts[0])==192) && (int(ip_parts[1])==168))
  {
    ip = parts[1];
    ip_received = true;
    tms_received = millis();
  }
}

/* -----------------------------------------------------------------------------
   Creates two strings from a decimal value with an input limitation from 0 to 255. 
---------------------------------------------------------------------------------
*/
String int2str(int inp)
{
  return (CodeTable[inp /16] + CodeTable[inp %16]); 
}


/* -----------------------------------------------------------------------------
   Dertermines if a finger or the mouse is over the area given by the 
   coordinates and the radius 
---------------------------------------------------------------------------------
*/
 boolean overCircle(int x, int y, int radius) {
  boolean result = false; 
  int disX = x - mouseX;
  int disY = y - mouseY;

  if (sqrt(sq(disX) + sq(disY)) < radius ) {
    result = true;
  } else {
    result = false;
  }
  return result;
 }


/* ---------------------------------------------------------------------
   This class implements the vertical control lever. 
   Parameter:
     cx: distance to the left screen border
     clim_pos_low: distance of the top guideway end to the top border
     clim_pos_high: distance of the lower guideway end to the top border
     channel: channel number (0..15) of the PWM module  
------------------------------------------------------------------------
*/
class Lever 
{
 int tx, ty, lim_pos_low, lim_pos_high, center_pos, cdefault_Pos; 
 int d, rgrid, px, py, dx, backlim_high, backlim_low;
 int valIdx = 0, ch, dist;
 String StrCh = "";
 int [] ValMap;
 // default_Pos 0..100
 Lever(int cx, int clim_pos_low, int clim_pos_high, int cdefault_Pos, int channel){  
   ch = channel;
   lim_pos_low = clim_pos_low;
   lim_pos_high = clim_pos_high;
   center_pos = ((lim_pos_high - lim_pos_low) * cdefault_Pos/100) + lim_pos_low;
   backlim_high =  center_pos + (lim_pos_high - lim_pos_low)/3;
   backlim_low =   center_pos - (lim_pos_high - lim_pos_low)/3;
   d = int(height * 0.2);
   rgrid = int(d* 0.75);
   py = center_pos;  // var for start up lever position 
   px = cx;
   StrCh = "C"+ str(ch);
   tx = int(cx * 0.65);
   ty = int(((lim_pos_high - lim_pos_low)/2  + lim_pos_low) * 1.03);
   ValMap = new int [int(lim_pos_high)+1];
   createValMap(int(lim_pos_low), int(lim_pos_high));
 }
 
 void display()
 { 
   stroke(90);
   strokeWeight(8);
   line (px, lim_pos_low , px, lim_pos_high); 
   fill(80); 
   text(StrCh, tx, ty);  
   dist = abs(center_pos - py);
   if (overCircle(px, py, rgrid)){
     py = constrain((mouseY), lim_pos_low, lim_pos_high); 
   }else{
      if ((py > int(center_pos))  && (py < backlim_high)){
        if (dist > 20) {
          py -= 3;     
        } else {  
          py -= 1;}
      }
      if ((py < int(center_pos)) &&  (py > backlim_low)){
        if (dist > 20) {
          py += 3;     
        } else {          
          py += 1;}       
      }  
    } 
    LeverHandle(px, py); 
  }
    
  void LeverHandle(int X_pos, int Y_pos ){
    strokeWeight(2);
    fill(#79c72e);
    ellipse(X_pos, Y_pos, d, d);
  }
  
/*
   Creates a table that maps the geografical position of the 
   lever to the interface value range needed for the 
   PWM device driver interface 0..254 (miniSSC protocol)
*/
 void createValMap(int min, int max){
    for (int i = min; i <= max; i++) { 
      ValMap [i] = round(map(i, max, min, 0, 254));
    }
  }
  
/**
   Creates the telegramm to transfer coded values for 
   header : 255
   ch: 0..15
   ValMap[setVal]: 0..254
*/
 String getVal(int setVal){
   return (int2str(255) + int2str(ch) + int2str(ValMap[setVal]));
 } 
}


/* -------------------------------------------------------------------------
   This class is an extention of the 'Lever' class and overwrites 
   the constructor and the  display method to rotate the coordinates:
     cx: distance to the left screen border
     clim_pos_low: distance of the left guideway end to the top border
     clim_pos_high: distance of the right guideway end to the top border
     channel: channel number (0..15) of the PWM module  
----------------------------------------------------------------------------
*/
class LeverT extends Lever{
  
  public LeverT(int ct, int clim_pos_low, int clim_pos_high, int cdefault_Pos, int channel){
    super (ct, clim_pos_low, clim_pos_high, cdefault_Pos, channel);
   py = ct;
   px = center_pos;
   ty = int(py * 1.45);
   tx = center_pos; 
   //LeverHandle(px, py);
   ValMap = new int [int(lim_pos_high)+1];
   createValMap(int(lim_pos_low), int(lim_pos_high));  
  }
  
  void display(){ 
   stroke(90);
   strokeWeight(8);
   line (lim_pos_low, py, lim_pos_high, py ); 
   fill(80); 
   textAlign(CENTER);
   text(StrCh, tx, ty);
   dist = abs(center_pos - px);
   if (overCircle(px, py, rgrid)){
     px = constrain((mouseX), lim_pos_low, lim_pos_high); 
     }
   else {
      if ((px > int(center_pos)) && (px < backlim_high)){
        if (dist > 20) {
          px -= 3;     
        } else { 
          px -= 1;
        }
      }
      if ((px < int(center_pos)) && (px > backlim_low)){
        if (dist > 20) {
          px += 3;     
        } else { 
          px += 1;
        }
      }
    }  
     LeverHandle(px, py); 
   }
 }

/*-------------------------------------------------------------------------
   This sclass draws the trim buttons and an indication 
   area to depict the current trim value. 
----------------------------------------------------------------------------
*/
class Trim {
  int r = int(height * 0.08), centerX, centerY, x1, x2, y1, y2, dist;
  int  valIdx = 0, ichannel, val; 
  String orientation;  //  "L" | "P"

  Trim (int cX, int cY, String orientation, int channel)
  {
    ichannel = channel;
    centerX = cX;
    centerY = cY; 
    val = 25;
    PFont Ltrimf;
    Ltrimf = createFont("Arial-BoldMT-16.vlw", 16);   
    textFont(Ltrimf, r/2);
    dist = int(height * 0.2);
    if (orientation == "P") {
      x1 = centerX;  
      x2 = centerX; 
      y1 = centerY - dist;
      y2 = centerY + dist;
    }else {
      y1 = centerY;  
      y2 = centerY; 
      x1 = centerX - dist;
      x2 = centerX + dist;    
    }
    displayVal();    
  }
  
  void display()
  {
    stroke(75);
    fill(100); 
    ellipse(x1, y1, r, r);
    ellipse(x2, y2, r, r);
    displayVal(); 
  }  
    
  void displayVal()
  {
    rect (centerX-r*0.5, centerY-r/2, r, r);
    fill(200);
    textAlign(CENTER);
    text(str(val-25) , centerX, centerY+r*0.2);  
  }
  
  boolean overT()
  {
    boolean result = false;
    if (overCircle(x1, y1, r))
    {
      val = val + 1;
      val = constrain (val, 0, 50);
      result = true;
    }
    if (overCircle(x2, y2, r))
    {
      val = val - 1;
      val = constrain (val, 0, 50);
      result = true;  
    }
    return result;
  }
  
  String getSval(){
    return (int2str(127) + int2str(ichannel) + int2str(val));
  }
}


/* --------------------------------------------------------------------------
   This class draws a switsch with two positions On - Off
      r: radius
      cx: distance to the left border of the screen
      cy: distance to the top border of the screen
      channel: channel number (0..15) of the PWM module
----------------------------------------------------------------------------
*/
class Switch {
  int SWh, SWr, SWx, SWy, SWOff, SWOn, SWd, pSWPos, SWytOn, SWytOff, SWgrid, SWhdr;
  int valIdx = 0, SWCh;
  String StrCh = "";
  
  Switch ( int r, int cx, int cy, int channel, int hdr)
  {
    SWr = r; 
    SWd = 2 * r;
    SWh = 4 * SWr; 
    SWx = cx;
    SWy = cy;
    SWytOn = SWy + int(3.5 * SWr); 
    SWytOff = SWy - int(2.5 * SWr);
    SWOff = SWy - SWr; 
    SWOn = SWy + SWr; 
    SWgrid = int(1.5 * SWr);
    pSWPos = SWOff;
    SWCh = channel;
    SWhdr = hdr;
    StrCh = "C"+ str(SWCh);     
  }

  void display(){
    rectMode(CENTER);
    stroke(75);
    fill(110); 
    rect(SWx, SWy, SWr, SWh, 1.5*SWr);  // base plate 
    drawLabel();
    if (pSWPos == SWOff)
    {
      fill(160);
    }else
    {
      fill(20, 150, 20);
    }
    ellipse (SWx, pSWPos,SWd, SWd);
    rectMode(CORNER);
  }
  
  void drawLabel() {
    fill(80); 
    textAlign(CENTER);
    text(StrCh, SWx, SWytOn); 
    text("", SWx, SWytOff); 
  }
    
  String getSval()
  {
    if (pSWPos == SWOff)
    {  
      return (int2str(SWhdr) + int2str(SWCh) + int2str(0));
    }else
    {
      return (int2str(SWhdr) + int2str(SWCh) + int2str(254));
    }
  }
  
  boolean overS()
  {
    boolean result = false;
    if (overCircle(SWx, SWOff, SWgrid))
    {
      pSWPos = SWOff;
      result = true; 
    }if (overCircle(SWx, SWOn, SWgrid))
    {
      pSWPos = SWOn;
      result = true;
    }
    return result;
  }
 }  

/* --------------------------------------------------------------------------
   This class is an extention of the 'Switch' class and overwrites 
   the default position and the knob labels
   With the header configuration of hdr = 100 it can power down
   the receiver.
----------------------------------------------------------------------------
*/ 
class SwitchApp extends Switch {
  public SwitchApp ( int r, int cx, int cy, int channel, int hdr){
    super (r, cx, cy, channel, hdr); 
    pSWPos = SWOn;
  }
  
  void drawLabel(){
    fill(80); 
    textAlign(CENTER);
    text("ON", SWx, SWytOn); 
    text("OFF", SWx, SWytOff);    
  }  
}

/* ----------------------------------------------------------------------------
  This class draws two buttons that act as seperate switches on one channel of
  PWM. This is required for simple play models without servo for steering.
----------------------------------------------------------------------------
*/
 class CtlBu2 {
  int centerX, centerY, dist, x1, x2, y1, y2, tx, ty, r, d;
  int valIdx = 0, ch, val;
  String StrCh = "";
  
  CtlBu2 (int cx, int cy, int channel){
     {
    r = int(height * 0.1);
    d = 2 * r; 
    ch = channel;
    centerX = cx;
    centerY = cy; 
    val = 127;
    tx = centerX;
    ty = int(centerY * 1.03);
    StrCh = "C"+ str(ch);
    dist = int(height * 0.2);
      y1 = centerY;  
      y2 = centerY; 
      x1 = centerX - dist;
      x2 = centerX + dist;    
    }    
  }

 void display()
    {
      stroke(75);
      strokeWeight(2);
      fill(#79c72e);
      ellipse(x1, y1, d, d);
      ellipse(x2, y2, d, d);
      fill(80);    
      text(StrCh, tx, ty);  
      val = 127;
      if (overCircle(x2, y2, r))
      {
        val = 0; 
      }
      if (overCircle(x1, y1, r))
      {
        val = 254; 
      }  
    }
 
 String getSval(){
    return (int2str(255) + int2str(ch) + int2str(val));
 }          
}
 
 
