/*-------------------------------------------------------------------------------
 Name:        Remote Control Transsmitter PC Version 
 Purpose:     Easy checking of methods on a PC without multitouch  
              Using as the baseline for a Android App   
 Author:      Bernd Hinze
 
 Created:     17.06.2019
 Copyright:   (c) Bernd Hinze 2019
 Licence:     MIT see https://opensource.org/licenses/MIT
 ------------------------------------------------------------------------------
 */
import hypermedia.net.*;
UDP udp;
int ERR_IP = 1, ERR_RPI = 2, ERR_UDP = 4, NO_ERR = 0;
// Start adaptation required
Lever L1; 
LeverT L2;
Trim T1;
Trim T2;
SwitchApp SApp;
SwitchTh STh;
SwitchDp SDp;
Indicator ICom;
// End adaptation 
PFont F;
String ip       = "";  // the remote IP address
int port        = 6100;    // the destination port
int tms_received = millis();
int tms_received_tout = 5 * 1000; // 5s
String [] CodeTable  =  {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?"}; 


void setup()
{
  orientation(LANDSCAPE); 
  background (#63aad0);
  F = createFont("Arial", 16, true); 
  textFont(F, int(height * 0.04));
  // Start adaptation required
  L1 = new Lever (int(width*0.25), int(height*0.15), int(height*0.85), int (50), 0);
  L2 = new LeverT (int(height*0.5), int(width*0.5), int(width*0.9), int (50), 4);
  T1 = new Trim(int(width * 0.09), int(height * 0.5), "P", 0);
  T2 = new Trim(int(width * 0.7), int(height * 0.8), "L", 4);
  SApp = new SwitchApp(int(height * 0.04), int(width * 0.7), int(height * 0.15), 15, 100, 0, 254); 
  STh = new SwitchTh(int(height * 0.04), int(width * 0.5), int(height * 0.15), 0, 105, 50, 100);
  SDp = new SwitchDp(int(height * 0.04), int(width * 0.4), int(height * 0.15), 0, 105, 50, 100);
  // End adaptation 

  ICom = new Indicator(0.95, 0.10);
  if (SIM)
  {
    ip  = "192.168.1.2";  // the remote IP address
    ICom.clear_err_state();
  }
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
  SApp.display();
  STh.display();
  SDp.display();
  // End Adaptation
  ICom.display();
  if ((ICom.err_state() & ERR_IP) == NO_ERR)   // ip valid
  {
    try {
      // Start adaptation required
      udp.send(L1.getVal(L1.py) + L2.getVal(L2.px), ip, port);
      // End Adaptation required
      // println(L1.getVal(L1.py) + L2.getVal(L2.px));
    }
    catch (Exception e) {
    }
  }
  if ((millis() - tms_received) > tms_received_tout) {
    ICom.set_err_state(ERR_RPI);
    // when timeout and rpi app has been switched off close the android app
    if ((millis() - tms_received) > tms_received_tout * 3) {
      if (ICom.app_state() == false) {
        exit();
      }
    }
  }
}


/* -------------------------------------------------------------------------
 The function draws the current state of the connction and the receiver ID 
 on the right corner of the screen.
 State: Bit 0 ip_not_received
 Bit 1 no rpi_message
 Bit 2 udp_send err
 ----------------------------------------------------------------------------   
 */
class Indicator 
{
  int tx, ty, ex, ey, ed, state;
  String tID, tor, trd;
  boolean RecApp;   
  Indicator(float x, float y)
  { 
    state = 7;
    RecApp = true;
    // geometry
    ex = int(width * x);
    ey = int(height * y);
    ed = int(height * 0.05);
    tx = int(width * (x - 0.03));
    ty = int(height * (y + 0.015)); 
    // text output
    tID = "";    
    trd = "No divice";
  }

  void set_app_state(boolean app)
  {
    RecApp = app;
  }

  boolean app_state()
  {
    return RecApp;
  }

  void set_err_state(int s)
  {
    state = (state | s) ;
  }

  void rem_err_state(int s)
  {
    state = (state & (7-s));
  }

  void clear_err_state()
  {
    state = 0;
    RecApp = true;
  }

  int err_state()
  {
    return state;
  }

  void set_device_name(String t)
  {
    tID = t;
  }

  void display() {
    textAlign(RIGHT);
    switch(state)
    {
    case 0: 
      // green, ip_received
      fill(#04C602);
      ellipse(ex, ey, ed, ed);
      fill(80);
      if (overI()){
        text(ip, tx, ty);
      } else {
        text(tID, tx, ty);  
      }     
      break; 
    case 2: 
      // orange, missing rpi msg
      fill(#FFF703);
      ellipse(ex, ey, ed, ed);
      fill(80);
      text("Rpi Error", tx, ty); 
      if (RecApp == false) {
        state = 1;
      }
      break; 
    case 4: 
      // orange, missing UPD error
      fill(#FFF703);
      ellipse(ex, ey, ed, ed);
      fill(80);
      text("UDP Error", tx, ty);    
      break; 
    default: 
      // afer startup, without commuication 
      fill(#FF0000);
      ellipse(ex, ey, ed, ed);
      fill(80);
      text("No Device", tx, ty);  
      break;
    }
  }
  
  boolean overI()
  {
    boolean result = false;
    if ((overCircle(ex, ey, ed)) != 0)
    {
      result = true;
    }
    return result;
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
  String[] ip_parts = split(parts[1], ".");
  // checking wether it is probably a IP adress
  if ((int(ip_parts[0])==192) && (int(ip_parts[1])==168))
  {
    ip = parts[1];
    ICom.clear_err_state(); 
    ICom.set_device_name(parts[0]);
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


/* ---------------------------------------------------------------------
 This class implements the vertical control lever. 
 Parameter:
 cx: distance to the left screen border
 clim_pos_low: distance of the top guideway end to the top border
 clim_pos_high: distance of the lower guideway end to the top border
 channel: channel number (0..15) of the PWM module  
 backspeed: amaount of picels the lever ist moved back in a draw cycle
 dist_ch_sp: distance from center the backspeed of level movement ist reduced
 ------------------------------------------------------------------------
 */
class Lever 
{
  int tx, ty, lim_pos_low, lim_pos_high, center_pos, cdefault_Pos; 
  int d, rgrid, px, py, dx;
  int valIdx = 0, ch, dist, backspeed, dist_ch_sp;
  String StrCh = "";
  int [] ValMap;

  // default_Pos 0..100
  Lever(int cx, int clim_pos_low, int clim_pos_high, int cdefault_Pos, int channel)
  {  
    ch = channel;
    lim_pos_low = clim_pos_low;
    lim_pos_high = clim_pos_high;
    backspeed = int(height * 0.04);       
    dist_ch_sp = int (backspeed * 1.1);
    center_pos = ((lim_pos_high - lim_pos_low) * cdefault_Pos/100) + lim_pos_low;
    d = int(height * 0.2);
    rgrid = int(d* 0.75);
    py = center_pos;  // var for start up lever position 
    px = cx;
    StrCh = "C"+ str(ch);
    tx = int(cx * 0.65);
    ty = int(((lim_pos_high - lim_pos_low)/2  + lim_pos_low) * 1.03);
    ValMap = new int [int(lim_pos_high)+1];
    adjustValMap(254, 0);
  }

  void display()
  { 
    stroke(90);
    strokeWeight(8);
    line (px, lim_pos_low, px, lim_pos_high); 
    fill(80); 
    text(StrCh, tx, ty);  
    valIdx = overCircle(px, py, rgrid);
    if (valIdx != 0) {
      py = constrain((mouseY), lim_pos_low, lim_pos_high);
    } else {
      dist = abs(center_pos - py);
      if (py > int(center_pos)) {
        if (dist > dist_ch_sp) {
          py -= backspeed;
        } else {  
          py -= 1;
        }
      }
      if (py < int(center_pos)){
        if (dist > dist_ch_sp) {
          py += backspeed;
        } else {          
          py += 1;
        }
      }
    } 
    LeverHandle(px, py);
  }
  
  void DefaultPos (int pos){
    center_pos = ((lim_pos_high - lim_pos_low) * pos/100) + lim_pos_low;
    py = center_pos;
  }

  void LeverHandle(int X_pos, int Y_pos ) {
    strokeWeight(2);
    fill(#79c72e);
    ellipse(X_pos, Y_pos, d, d);
  }

  /*
   Creates a table that maps the geografical position of the 
   lever to the interface value range needed for the 
   PWM device driver interface 0..254 (miniSSC protocol)
   */
  void adjustValMap(int vpmin, int vpmax) {   
    for (int i = int(lim_pos_low); i <= lim_pos_high; i++) { 
      ValMap [i] = round(map(i, lim_pos_low, lim_pos_high, vpmin, vpmax));
    }
  }

  /**
   Creates the telegramm to transfer coded values for 
   header : 255
   ch: 0..15
   ValMap[setVal]: 0..254
   */
  String getVal(int setVal) {
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
class LeverT extends Lever 
{

  public LeverT(int ct, int clim_pos_low, int clim_pos_high, int cdefault_Pos, int channel) {
    super (ct, clim_pos_low, clim_pos_high, cdefault_Pos, channel);
    py = ct;
    px = center_pos;
    ty = int(py * 1.45);
    tx = center_pos;
    adjustValMap(0, 254);
  }

  void display() { 
    stroke(90);
    strokeWeight(8);
    line (lim_pos_low, py, lim_pos_high, py ); 
    fill(80); 
    textAlign(CENTER);
    text(StrCh, tx, ty);
    valIdx = overCircle(px, py, rgrid);
    if (valIdx != 0) {
      px = constrain((mouseX), lim_pos_low, lim_pos_high);
    } else {
      dist = abs(center_pos - px);
      if (px > int(center_pos)) {
        if (dist > dist_ch_sp) {
          px -= backspeed;
        } else { 
          px -= 1;
        }
      }
      if (px < int(center_pos)) {
        if (dist > dist_ch_sp) {
          px += backspeed;
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
class Trim 
{
  int r = int(height * 0.08), centerX, centerY, x1, x2, y1, y2, dist;
  int  valIdx = 0, ichannel, val; 
  String orientation;  //  "L" | "P"

  Trim (int cX, int cY, String orientation, int channel)
  {
    ichannel = channel;
    centerX = cX;
    centerY = cY; 
    val = 25;
    dist = int(height * 0.2);
    if (orientation == "P") {
      x1 = centerX;  
      x2 = centerX; 
      y1 = centerY - dist;
      y2 = centerY + dist;
    } else {
      y1 = centerY;  
      y2 = centerY; 
      x1 = centerX + dist;
      x2 = centerX - dist;
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
    text(str(val-25), centerX, centerY+r*0.2);
  }

  boolean overT()
  {
    boolean result = false;
    if ((overCircle(x1, y1, r)) != 0)
    {
      val = val + 1;
      val = constrain (val, 0, 50);
      result = true;
    }
    if ((overCircle(x2, y2, r)) != 0)
    {
      val = val - 1;
      val = constrain (val, 0, 50);
      result = true;
    }
    return result;
  }

  String getSval() {
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
class Switch 
{
  int SWh, SWr, SWx, SWy, SWOff, SWOn, SWd, pSWPos, SWytOn, SWytOff, SWgrid, SWhdr;
  int valIdx = 0, SWCh, SWxc, SWyc, SWvON, SWvOFF;
  String StrCh = "";

  Switch ( int r, int cx, int cy, int channel, int hdr, int off, int on)
  {
    SWr = r; 
    SWd = 2 * r;
    SWh = 4 * SWr; 
    SWx = cx;
    SWy = cy;
    SWytOn = SWy - int(2.5 * SWr); 
    SWytOff = SWy + int(3.5 * SWr);
    SWOff = SWy + SWr; 
    SWOn = SWy - SWr; 
    SWgrid = int(1.5 * SWr);
    pSWPos = SWOff;
    SWCh = channel;
    SWhdr = hdr;
    SWxc = (SWx - int(width * 0.05));
    SWyc = (SWytOn - int((SWytOn - SWytOff)*0.5));  
    StrCh = str(SWCh);
    SWvON = on; 
    SWvOFF = off;
  }

  void display()
  {
    rectMode(CENTER);
    stroke(75);
    fill(110); 
    rect(SWx, SWy, SWr, SWh, 1.5*SWr);  // base plate 
    drawLabel();
    if (pSWPos == SWOff)
    {
      fill(160);
    } else
    {
      fill(20, 150, 20);
    }
    ellipse (SWx, pSWPos, SWd, SWd);
    rectMode(CORNER);
  }

  void drawLabel() 
  {
    fill(80); 
    textAlign(CENTER);
    text("ON", SWx, SWytOn); 
    text("OFF", SWx, SWytOff);
    text("C" + StrCh, SWxc, SWyc);  
  }

  String getSval()
  {
    if (pSWPos == SWOff)
    {  
      return (int2str(SWhdr) + int2str(SWCh) + int2str(SWvOFF));
    } else
    {
      return (int2str(SWhdr) + int2str(SWCh) + int2str(SWvON));
    }
  }
  
  int getIval()
  {
    if (pSWPos == SWOff)
    { 
      return SWvOFF;
    } else {
      return SWvON;
    }
  }

  boolean overS()
  {
    boolean result = false;
    if (overCircle(SWx, SWOff, SWgrid) != 0)
    {
      pSWPos = SWOff;
      result = true;
    }
    if (overCircle(SWx, SWOn, SWgrid) !=0)
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
class SwitchApp extends Switch 
{
  public SwitchApp ( int r, int cx, int cy, int channel, int hdr, int off, int on) {
    super (r, cx, cy, channel, hdr, off, on); 
    pSWPos = SWOn;
  }

  void drawLabel() {
    fill(80); 
    textAlign(CENTER);
    text("ON", SWx, SWytOn); 
    text("OFF", SWx, SWytOff);
    text("PI", SWxc, SWyc);
  }
}


/* --------------------------------------------------------------------------
 This class is an extention of the 'Switch' class and overwrites 
 the default position and the knob labels
 With the header configuration of hdr = 105 it can threshold a channel of 
 the receiver.
 ----------------------------------------------------------------------------
 */
class SwitchTh extends Switch 

{
  public SwitchTh ( int r, int cx, int cy, int channel, int hdr, int off, int on) {
    super (r, cx, cy, channel, hdr, off, on); 
    pSWPos = SWOn;
  }

  void drawLabel() {
    fill(80); 
    textAlign(CENTER);
    text("100%", SWx, SWytOn); 
    text("50%", SWx, SWytOff);
    text("TH"+StrCh, SWxc, SWyc);
  }
}

/* --------------------------------------------------------------------------
 This class is an extention of the 'Switch' class and overwrites 
 the default position and the knob labels
 With the header configuration of hdr = 105 it can threshold a channel of 
 the receiver.
 ----------------------------------------------------------------------------
 */
class SwitchDp extends Switch 

{
  public SwitchDp ( int r, int cx, int cy, int channel, int hdr, int off, int on) {
    super (r, cx, cy, channel, hdr, off, on); 
    pSWPos = SWOff;
  }

  void drawLabel() {
    fill(80); 
    textAlign(CENTER);
    text("100%", SWx, SWytOn); 
    text("50%", SWx, SWytOff);
    text("DP"+StrCh, SWxc, SWyc);
  }
}
