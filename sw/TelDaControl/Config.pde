/*-------------------------------------------------------------------------------
 Name:        Mode dependig routines for Android app 
 Purpose:     Testing of servos at channel 0..14 and switches at channel 15
 
 Author:      Bernd Hinze
 
 Created:     03.05.2019
 Copyright:   (c) Bernd Hinze 2019
 Licence:     MIT see https://opensource.org/licenses/MIT
 ------------------------------------------------------------------------------
 */
 
import android.content.Context;
import android.app.Notification;
import android.app.NotificationManager;
NotificationManager gNotificationManager;
Notification gNotification;
long[] gVibrate = {0,100}; 

boolean SIM = false; 

void settings(){
  fullScreen();
}

/* -----------------------------------------------------------------------------
   Dertermines if a finger is over the area given by the 
   coordinates and the radius - Android version
---------------------------------------------------------------------------------
*/
  int overCircle(int x, int y, int radius) 
  {
   int valIdx = 0; 
   for (int i = 0;  i < touches.length; i++){
    int disX = x - int(touches[i].x);
    int disY = y - int(touches[i].y);
    if ((sqrt(sq(disX) + sq(disY)) < radius ) 
       && (valIdx == 0)){
        valIdx = i + 1 ;  // caused 0 is not valid, shifting
       }
   }
   return valIdx;
  }


/* -----------------------------------------------------------------------------
 Dertermines if a finger or the mouse is touching the scree and change the state of 
 switches 
 ---------------------------------------------------------------------------------
*/

void touchStarted()
{ 
  // Start adaptation required  
  if ((ICom.err_state() & ERR_IP) == NO_ERR) // ip valid
  {
    if (T1.overT())
    { 
      //println (T1.getSval());
      if (udp.send(T1.getSval(), ip, port) == false)
      {
        ICom.set_err_state(ERR_UDP);
      }
    }
    if (T2.overT())
    {
      //println (T2.getSval());
      if (udp.send(T2.getSval(), ip, port) == false)
      {
        ICom.set_err_state(ERR_UDP);
      }
    }
    if (SApp.overS())
    {
      if (udp.send(SApp.getSval(), ip, port) == false)
      {
        ICom.set_err_state(ERR_UDP);
      }
      if (SApp.getSval().substring(4, 6).equals("00")) {
        ICom.set_app_state(false);
      }
    }
  }  


  if (STh.overS())
  {
    if (STh.getIval() == 50) {
      if (SDp.getIval() == 50) {
        L1.adjustValMap(190, 64);
      } else {
        L1.adjustValMap(127, 0); 
      }
    } else {
      L1.adjustValMap(254, 0);
    }
  }
  
  if (SDp.overS())
  {
    if (STh.getIval() == 100)
    {
      if (SDp.getIval() == 50)
      {
        L1.DefaultPos (50);
      } else {
        L1.DefaultPos (100);
      }
    } else {
      if (SDp.getIval() == 50) {
        L1.DefaultPos (50);
        L1.adjustValMap(190, 64);
      } else {
        L1.adjustValMap(127, 0); 
        L1.DefaultPos (100);
      }   
    }
  }  
} 
 // End adaptation
 
