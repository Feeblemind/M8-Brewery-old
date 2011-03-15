//One Wire
#include <OneWire.h>

//Ethernet includes
#include <SPI.h>
#include <Ethernet.h>
#include <Client.h>
#include <Server.h>
#include <Udp.h>

//Store stuff in program memory
#include <avr/pgmspace.h>

//My Libraries
#include "M8_Constants.h" //Include the constants

#include "MemoryFree.h" //Include a free memory checker

#include "M8_PID.h" //Include my PID class
#include "M8_SSR.h" //Include my SSR handling class
#include "M8_TempMgr.h" //Include my 12BS20 oneWire manager class
#include "M8_Web.h" // Include my Web Server

//// ******************  Hookup Diagram
//   0 RX         "BT TX",
//   1 TX         "BT RX",
//   2            "",
//   3 PWM        "SSR",
//   4            "Ethernet Shield",
//   5 PWM        "OneWire",
//   6 PWM        "",
//   7            "",
//   8            "",
//   9 PWM        "",
//  10 PWM        "Ethernet Shield",
//  11 PWM        "Ethernet Shield",
//  12            "Ethernet Shield",
//  13 LED        "Ethernet Shield",
//  A0            "",
//  A1            "",
//  A2            "",
//  A3            "",
//  A4            "",
//  A5            ""

//// *******************  Program loop variables
boolean dumpData = false; // Dump the data to the serial line?
boolean graphMode = false; //Dumps data to a easly imported format
unsigned long tempRead = 0; // The millis() value to read the next set of temps at
 
//// *******************  Serial input variables
String inputString; //Test Command
boolean EOS = false; //End of String
boolean debugMode = false; //Are we in debug mode? 

//// *******************  Ethernet variables lets store these in program memory
PROGMEM byte mac[]     = { 0x90, 0xA2, 0xDA, 0x00, 0x14, 0x14};
PROGMEM byte ip[]      = { 192, 168,   1, 120 }; // Should be EEPROM
PROGMEM byte gateway[] = { 192, 168,   1,   1 }; // Should be EEPROM
PROGMEM byte subnet[]  = { 255, 255, 255,   0 }; // Should be EEPROM

// Initialize the Ethernet server library
// with the IP address and port you want to use 
// (port 80 is default for HTTP):
Server server( 80 );

//// *******************  SSR control variables
class M8_SSR SSR;

//// *******************  PID Controller variables 
class M8_PID PID; //The results from updatePID(temp,targetTemp);

//// *******************  Web Server
class M8_WebServer webServer;

//// *******************  TempMgr variables
OneWire ow( oneWirePin );
class M8_TempMgr tempMgr;

//**************************************************************************************************
//                                             Setup!
//**************************************************************************************************
void setup(void)
{
  Serial.begin(9600);  
  
  Serial.print("Setting up the TempMgr...");
  tempMgr.setupTempMgr( &ow );  // Send the tempMgr a One Wire object
  Serial.print("SensorCount = ");
  Serial.print( sensorCount );
  Serial.println("...Done!");
  
  Serial.print("Setting up SSR Outputs...");  
  SSR.setupSSR( SSRPin );
  SSR.setPower( 0 );
  Serial.print("calling updateSSR()...");
  updateSSR();
  Serial.println("Done!");
    
  // start the Ethernet connection and the server:
  Serial.print("Setting up web Server...");
  Ethernet.begin(mac, ip, gateway, subnet);
  Serial.print("Starting server...");
  server.begin();
  Serial.print("Setting up Web Server ...");
  webServer.setupWebServer( &server, &PID, &SSR, &tempMgr);
  Serial.println("Done!");

  //setup the PID
  Serial.print("Setting up the PID...");
  for ( byte i=0; i< sensorCount; i++ )
  {
    PID.setupPID( i, defaultPGain, defaultIGain, defaultDGain, defaultIStateMin, defaultIStateMax );
  };
  Serial.println("Done!");
    
  Serial.print("Free Memory = ");
  Serial.println( freeMemory() );    
    
  Serial.println("Leaving Setup");
}
  
//// Turn the SSR pin on or off depending on the SSROn variable.
void updateSSR( void )
{
  //Note, we only have one SSR ...
  SSR.update();
}


////  Append received data to the inputString, set a flag when we get a carrage return.
void appendSerialData ( void )
{
   if (Serial.available())
   {
     char readChar = Serial.read();
     Serial.print( readChar ); //Echo it back
     
     if (readChar == '\r') // did we get a carrage return?
     {
       //Echo back a println
       Serial.println();
       EOS = true;
     }
     else
       inputString.concat( readChar );
   }
   else
   {
     //No Data to input
   }
}
        
void doSetTemp( String input )
/*
  uses input string to set a desired thermometer's target temp and hold time
  
  input string should have the following format:
  T#0C20;
  T - the set hold command
  #0 - the theremometer to set, in this case  0
  C20 - the temp (in C) to set, in this case 20
  ; - the end of the command
*/
{
  byte thermometer = -1; // Which theremometer are we adjusting?
  byte setTemp = -1;     // The temp to hold at
  byte temp, temp2, temp3; // Throw away varibles
  String str; // Throw away string

  if (debugMode)
  {
    Serial.print("In doSetHoldTemp...");
    Serial.print(input);
    Serial.print("...");
  }
 
  //find the "#"
  temp = input.indexOf('#');
  //find the "C"
  temp2 = input.indexOf('C');
  //find the ";"
  temp3 = input.indexOf(';');
  
  if ( debugMode )
  {
    Serial.print("index of #=");
    Serial.print(temp,DEC);
    Serial.print(" C=");
    Serial.print(temp2,DEC);
    Serial.print(" ;=");
    Serial.print(temp3,DEC); 
  }
  
  if ( ( temp < 0 ) || ( temp2 < 0 ) || ( temp3 < 0 ) )
  {
    //Error!
    Serial.print("ERROR: H Command not properly formated!");
    Serial.print("  ");
    Serial.println( input );

    return; // get outa here!
  }
  
  //The theremometer should be temp -> temp2
  str = input.substring( temp+1, temp2 );
  if ( debugMode )
  {
    Serial.print( " Thermometer = ");
    Serial.print( str );
  }
  thermometer = str.toInt();
  
  //The Temp in C should be temp2->temp3
  str = input.substring( temp2+1, temp3 );
  if ( debugMode )
  {
    Serial.print( " Set Temp = ");
    Serial.print( str );
  }
  setTemp = str.toInt();
  
  tempMgr.setTargetTemp( thermometer, setTemp );

  if ( debugMode )
    Serial.print(" Reseting PID ");
  
  PID.setupPID( thermometer, defaultPGain, defaultIGain, defaultDGain, defaultIStateMin, defaultIStateMax );
  
  if ( debugMode )
    Serial.println(" ...Done with H");
}

//**************************************************************************************************
//                                             COMMANDS!
//**************************************************************************************************  
void doCommand( void )
{
  Serial.print("Processing \"");
  Serial.print(inputString);
  Serial.println("\"");
  
  switch ( inputString[0] )
  {      
    case 'H' :
      doSetTemp( inputString );
      break;
      
    case 'D' : // Toggle Data Dump, tells the program to output the data
      dumpData = !dumpData; // Toggle data dump
      break;
      
    case 'd' : // Do one dump
      doDataDump();
      break;
            
    case 'G' : // Toggle Graph dump mode
      Serial.println("Be sure that you've toggled everything else off");
      
      //Make sure that we've turned everything off!
      if ( debugMode )
        Serial.println("Turn off debugMode! (V)");
      if ( dumpData )
        Serial.println("Turn off dumpData! (D)");
        
      Serial.println("Once those are turned off do G to start graph mode");
      graphMode = !graphMode;
        
      //If we're in graphMode, throw up a header  
      if (graphMode)
        doGraphModeHeader();              
      break;  
      
    case 'V' : // Toggle Debug Mode
      debugMode = !debugMode;
      
      if ( debugMode )
        Serial.println("DEBUG MODE!");
      break;
      
    case 'T' : // Set hold temp
        doSetTemp( inputString );
      break;
      
    case 'J' : // Jiffies!
      Serial.print("Power level=");
      Serial.print( SSR.getPower() );
      
      if ( inputString[1] == '+' )
      {  // J+ Inc
        SSR.setPower( SSR.getPower() + 5 );
      }
      else if ( inputString[1] == '-' )
      { //J- Dec
        SSR.setPower( SSR.getPower() - 5 );
      }
      else  //J just tells us the power.
        break;
      
      Serial.print(" New Power level=");
      Serial.println( SSR.getPower() );
      break;
            
// ***** DEBUG MODE COMMANDS *****
            
  }
          
  if ( EOS )
  {
    inputString = "";
    EOS = false;
    //Print out a prompt w/ the flags
    if ( debugMode )
      Serial.print("V");
    if ( dumpData )
      Serial.print("D");
    if ( graphMode )
      Serial.print("G");
    Serial.print(">");
  }
  else
  {
    //Why are we even here?
    Serial.print("ERROR:Shouldn't be in doCommand(");
    Serial.print(inputString);
    Serial.println(")!!!");
  }
}
 
void doDataDump( void )
// Dumps out alot of data for debuging
{
  Serial.println( millis() );
  
  for (byte i=0; i< sensorCount; i++)
  {
    Serial.print("Curr[");
    Serial.print(i, DEC);
    Serial.print("]=");
    Serial.print(tempMgr.getTempC(i));
    
    Serial.print(",Targ[");
    Serial.print(i, DEC);
    Serial.print("]=");
    Serial.print(tempMgr.getTargetTemp(i));
        
    Serial.print(",PID[");
    Serial.print(i, DEC);
    Serial.print("]=");
    Serial.print( PID.getValue( i ) );
    
    Serial.println();
  };
  
  Serial.print("SSR State:");
  Serial.print( SSR.getPower() );
  Serial.print("%/");
  Serial.print( SSR.getJiffy() );
  Serial.println("j");
  
  Serial.print("Free Memory = ");
  Serial.println( freeMemory() );    
  
  Serial.println("*******************************");
}

void doGraphModeHeader( void )
{
  Serial.print("Time,"); 
  for (byte i=0;i<sensorCount;i++)
  {
    Serial.print("Temp ");
    Serial.print(i);
    Serial.print(", Target ");
    Serial.print(i);
        
    Serial.print(", PID Value ");
    Serial.print(i);
    Serial.print(", P Term ");
    Serial.print(i);
    Serial.print(", I Term ");
    Serial.print(i);
    Serial.print(", D Term ");
    Serial.print(i);
    Serial.print(", P Gain ");
    Serial.print(i);
    Serial.print(", I Gain ");
    Serial.print(i);
    Serial.print(", D Gain ");
    Serial.print(i);
  }
  Serial.print(", SSR Power ");    
  Serial.print(", SSR Jiffy ");
}
 
void doGraphMode( void )
{
  Serial.print( millis() );
  Serial.print(",");
  
  for (byte i=0; i< sensorCount; i++)
  {
    Serial.print(tempMgr.getTempC(i));
    Serial.print(",");
    Serial.print(tempMgr.getTargetTemp(i));
    Serial.print(",");
        
    Serial.print( PID.getValue(i) );
    Serial.print(",");

    Serial.print( PID.getPTerm(i) );
    Serial.print(",");
    Serial.print( PID.getITerm(i) );
    Serial.print(",");
    Serial.print( PID.getDTerm(i) );
    Serial.print(",");    
    
    Serial.print( PID.getPGain(i) );
    Serial.print(",");
    Serial.print( PID.getIGain(i) );
    Serial.print(",");
    Serial.print( PID.getDGain(i) );
    Serial.print(",");    
  };

  Serial.print( SSR.getPower() );
  Serial.print(",");
  Serial.print( SSR.getJiffy() );
  
  Serial.println();
};

//**************************************************************************************************
//                                             Main Loop!
//**************************************************************************************************
void loop(void)
{  
  // ***** Listen for incoming inputs
  appendSerialData(); // Read in serial data
  // Comment out this line for a savings of almost 600 Bytes of ram
  webServer.doListenForClients(); // check for incoming Ethernet connections:
  
  if ( EOS ) // Process any complete commands
    doCommand();

  if ( tempMgr.update() == true ) // Don't need to check if we didn't update the temps       
  {
    for ( byte i=0; i< sensorCount; i++ )
    {
      // update the PID
      PID.calcPID( i, tempMgr.getTempC( i ), tempMgr.getError( i ) );
      // And the SSR power level
      // We only have one SSR:
      if ( i == 0 )
        SSR.setPower( PID.getSSRValue( i ) );
    }  
    
    if ( graphMode )  
      if ( !dumpData && !debugMode )
        doGraphMode();
      else
      {     
        Serial.println("TURN OFF THE OTHER MODES!");
        graphMode = !graphMode;
      }
      
      if ( dumpData )
        doDataDump();
  };
    
  updateSSR(); //Cycle the SSR(s)
}
