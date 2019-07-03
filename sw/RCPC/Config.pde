/*-------------------------------------------------------------------------------
 Name:        Mode dependig routines for PC app
 Purpose:     Testing of servos at channel 0..14 and switches at channel 15
 
 Author:      Bernd Hinze
 
 Created:     03.05.2019
 Copyright:   (c) Bernd Hinze 2019
 Licence:     MIT see https://opensource.org/licenses/MIT
 ------------------------------------------------------------------------------
 */

boolean SIM = true; 

void settings() {
  size(800, 400);
}

/* -----------------------------------------------------------------------------
 Dertermines if the mouse is over the area given by the 
 coordinates and the radius - PC version
 ---------------------------------------------------------------------------------
 */
int overCircle(int x, int y, int radius) {
  int result = 0; // means false 
  int disX = x - mouseX;
  int disY = y - mouseY;

  if (sqrt(sq(disX) + sq(disY)) < radius ) {
    result = 1;
  } else {
    result = 0;
  }
  return result;
}

int overArea(int x, int y, int grid, String ori) {
  int result = 0; // means false 
  int gridline = grid * 2;
  int disX = abs(x - mouseX);
  int disY = abs(y - mouseY);

  if (ori == "P") {
    if ((disX < grid ) && (disY < gridline)) {
      result = 1;
    } else {
      result = 0;
    }
  } else {
    if ((disX < gridline ) && (disY < grid)) {
      result = 1;
    } else {
      result = 0;
    }
  }
  return result;
}


/* -----------------------------------------------------------------------------
 Dertermines if a finger or the mouse is touching the scree and change the state of 
 switches 
 ---------------------------------------------------------------------------------
 */

void mousePressed()
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
