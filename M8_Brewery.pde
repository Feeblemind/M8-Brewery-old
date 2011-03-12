//One Wire
#include <OneWire.h>

//Ethernet includes
#include <SPI.h>
#include <Ethernet.h>
#include <Client.h>
#include <Server.h>
#include <Udp.h>

//My Libraries
#include "M8_Constants.h" //Include the constants

#include "M8_PID.h" //Include my PID class
#include "M8_SSR.h" //Include my SSR handling class
#include "M8_TempMgr.h" //Include my 12BS20 oneWire manager class

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

//// *******************  Ethernet variables 
byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x14, 0x14};
byte ip[]      = { 192, 168,   1, 120 };
byte gateway[] = { 192, 168,   1,   1 };	
byte subnet[]  = { 255, 255, 255,   0 };

// Initialize the Ethernet server library
// with the IP address and port you want to use 
// (port 80 is default for HTTP):
Server server( 80 );

//// *******************  SSR control variables
class M8_SSR SSR;

//// *******************  PID Controller variables 
class M8_PID PID[ sensorCount ]; //The results from updatePID(temp,targetTemp);

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
  Serial.println("Done!");
  
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
  Serial.println("Done!");
  
  //setup the PID
  Serial.print("Setting up the PID...");
  for ( int i=0; i< sensorCount; i++ )
  {
    PID[i].setupPID( defaultPGain, defaultIGain, defaultDGain, defaultIStateMin, defaultIStateMax, defaultUpdateInterval );
  };
  Serial.println("Done!");
    
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
      
void doSetPIDGain( String input )
{
/*
  uses input string to set a PID gain value
  
*/
  unsigned int temp, temp1;
  temp1 = input.indexOf(';');  
  
  if ( input[0] != 'P' )
    return; // Should be an error
    
  switch ( input[1] ) 
  {
    case 'p':
      //read in a new pGain
      break;
    case 'i':
      //read in a new iGain  
      break;
    case 'd':
      //read in a new dGain
      break;
  }  
};
  
void doSetHoldTemp( String input )
/*
  uses input string to set a desired thermometer's target temp and hold time
  
  input string should have the following format:
  H#0C20;
  H - the set hold command
  #0 - the theremometer to set, in this case  0
  C20 - the temp (in C) to set, in this case 20
  ; - the end of the command
*/
{
  int thermometer = -1; // Which theremometer are we adjusting?
  int setTemp = -1;     // The temp to hold at
  int temp, temp2, temp3; // Throw away varibles
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
    Serial.print(temp);
    Serial.print(" C=");
    Serial.print(temp2);
    Serial.print(" ;=");
    Serial.print(temp3); 
  }
  
  if ( ( temp < 0 ) || ( temp2 < 0 ) || ( temp3 < 0 ) )
  {
    //Error!
    Serial.println("ERROR: H Command not properly formated!");
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
  
  PID[ thermometer ].setupPID( defaultPGain, defaultIGain, defaultDGain, defaultIStateMin, defaultIStateMax, defaultUpdateInterval );
  
  if ( debugMode )
    Serial.println(" ...Done with H");
}

// Just a utility function to nicely format an IP address.
const char* ip_to_str(const uint8_t* ipAddr)
{
  static char buf[16];
  sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  return buf;
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
    case 'n' : // Dump some network info
      Serial.println("IP addr = ");
      Serial.println(ip_to_str(ip));
      break;
      
    case 'D' : // Toggle Data Dump, tells the program to output the data
      dumpData = !dumpData; // Toggle data dump
      break;
      
    case 'd' : // Do one dump
      doDataDump();
      break;
      
    case 'P' : //Dump PID info
//      PID[0].doDebug();
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
      
    case 'H' : // Set hold temp
        doSetHoldTemp( inputString );
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
      
    case 'j':
      Serial.print( "Jiffies = " );
      Serial.println( SSR.getJiffy() );
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
  
  for (int i=0; i< sensorCount; i++)
  {
    Serial.print("Curr[");
    Serial.print(i);
    Serial.print("]=");
    Serial.print(tempMgr.getTempC(i));
    
    Serial.print(",Targ[");
    Serial.print(i);
    Serial.print("]=");
    Serial.print(tempMgr.getTargetTemp(i));
        
    Serial.print(",PID[");
    Serial.print(i);
    Serial.print("]=");
    Serial.print( PID[i].getValue() );

    Serial.print(",heat");
    Serial.print( SSR.getPower() );
    Serial.print("/");
    Serial.print( SSR.getJiffy() );
    
    Serial.println();
  };
  
  Serial.println("*******************************");
}

void doGraphModeHeader( void )
{
  Serial.print("Time,"); 
  for (int i=0;i<sensorCount;i++)
  {
    Serial.print("Temp ");
    Serial.print(i);
    Serial.print(", Target ");
    Serial.print(i);
    
    Serial.print(", Hold Count ");
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

    
    Serial.print(", SSR Power ");
    Serial.print(i);
    
    Serial.print(", SSR Jiffy ");
    Serial.print(i);
  }
}
 
void doGraphMode( void )
{
  Serial.print( millis() );
  Serial.print(",");
  
  for (int i=0; i< sensorCount; i++)
  {
    Serial.print(tempMgr.getTempC(i));
    Serial.print(",");
    Serial.print(tempMgr.getTargetTemp(i));
    Serial.print(",");
        
    Serial.print( PID[i].getValue() );
    Serial.print(",");

    Serial.print( PID[i].getPTerm() );
    Serial.print(",");
    Serial.print( PID[i].getITerm() );
    Serial.print(",");
    Serial.print( PID[i].getDTerm() );
    Serial.print(",");    
    
    Serial.print( PID[i].getPGain() );
    Serial.print(",");
    Serial.print( PID[i].getIGain() );
    Serial.print(",");
    Serial.print( PID[i].getDGain() );
    Serial.print(",");    
    
    Serial.print( SSR.getPower() );
    Serial.print(",");
    Serial.print( SSR.getJiffy() );
    Serial.print(",");
  };
  
  Serial.println();
};

//**************************************************************************************************
//                                             WEB PAGES!
//**************************************************************************************************  
void doListenForClients() {
  // listen for incoming clients
  Client client = server.available();
    
  if (client) {
    if ( debugMode)
      Serial.println("Got a web client");
      
    // an http request ends with a blank line   
    boolean currentLineIsBlank = true;
    
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        Serial.print(c);
        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank) {
          // send a standard http response header
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: text/html");
          client.println();
          client.println("<html>");
          client.println("<head>");
          client.println("  <title>M8 Brewery</title>");
//          client.print("  <meta http-equiv=\"refresh\" content=\"");
//          client.print( webPageUpdateTime );
//          client.println("\">");
          client.println("</head>");
          
          client.println("<body>");
          // print the current readings, in HTML format:
          client.println( "<h3> Current Status </h3>" );
          
          client.print( "<h5> Time is " );
          client.print( millis() );
          client.println( "</h5>" );
          
          //Display the themrometers in a table
          client.println("<table border=\"1\"> ");
          client.println("<tr>");
          client.println("<th>Sensor</th>");
          client.println("<th>Current Temp C</th>");          
          client.println("<th>Target Temp</th>");
          client.println("<th>PID Result</th>");
          client.println("<th>Heat Power (%/j)</th>");
          client.println("</tr>");
          
          for (int i=0; i< sensorCount; i++)
          {
            client.print("<tr>");
            
            client.print("<td>");
            client.print(i);
            client.print("</td>");
            
            client.print("<td>");
            client.print(tempMgr.getTempC(i));
            client.print("</td>");
            
            client.print("<td>");
            client.print(tempMgr.getTargetTemp(i));
            client.print("</td>");
        
            client.print("<td>");
            client.print( PID[i].getValue() );
            client.print("</td>");

            client.print("<td>");
            client.print( SSR.getPower() );
            client.print("% / ");
            client.print( SSR.getJiffy() );
            client.print("</td>");
            client.println("</tr>");
          };

          client.println("</table>");
          
          client.println("<form name=\"input\" action=\"yournewtemp\" method=\"get\">");
          client.println("New Target Temp: <input type=\"text\" name=\"newTemp\" />");
          client.println("<input type=\"submit\" value=\"Submit\" />");
          client.println("</form>"); 
          
          client.println("</body>");
          client.println("</html>");
          
          break;
        }
        if (c == '\n') {
          // you're starting a new line
          currentLineIsBlank = true;
        } 
        else if (c != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
        }
      }
    }
    // give the web browser time to receive the data
    delay(1);
    // close the connection:
    client.stop();
  }
}  
 
//**************************************************************************************************
//                                             Main Loop!
//**************************************************************************************************
 
void loop(void)
{
  boolean newData = false; // do we have new data to dump?
    
  // ***** Listen for incoming inputs
  appendSerialData(); // Read in serial data
  doListenForClients(); // check for incoming Ethernet connections:
  
  newData = tempMgr.update();
  
  if ( EOS ) // Process any complete commands
    doCommand();

  if ( newData ) // Don't need to check if we didn't update the temps       
    for ( int i=0; i< sensorCount; i++ )
    {
      // update the PID
      PID[ i ].calcPID( tempMgr.getTempC( i ), tempMgr.getError( i ) );
      // And the SSR power level
      SSR.setPower( PID[i].getValue() );
      
      if ( graphMode )  
        if ( !dumpData && !debugMode )
          doGraphMode();
        else
        {     
          Serial.println("TURN OFF THE OTHER MODES!");
          graphMode = !graphMode;
        }      
    };
    
  updateSSR(); //Cycle the SSR(s)
  
  if ( dumpData && newData )
    doDataDump();    
}
