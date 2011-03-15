#ifndef M8_WEB_CPP
#define M8_WEB_CPP

#include "WProgram.h"
#include "M8_Web.h"
#include "MemoryFree.h"

void M8_WebServer::setupWebServer( Server *server, M8_PID *PID, M8_SSR *SSR, M8_TempMgr *tempMgr )
{
  _server = server;
  _PID = PID;
  _SSR = SSR;
  _tempMgr = tempMgr;
}

void M8_WebServer::_doServeBasicHeader( Client *client )
{
  client->println("HTTP/1.1 200 OK");
  client->println("Content-Type: text/html");
  client->println();
};

void M8_WebServer::_doServePage( Client *client )
{
  client->println("<html>");
  client->println("<head>");
  client->println("  <title>M8 Brewery</title>");
  client->println("</head>");
  
  client->println("<body>");
  // print the current readings, in HTML format:
  client->println( "<h3> Current Status </h3>" );
  
  client->print( "<h5> Time is " );
  client->print( millis() );
  client->println( "</h5>" );
  
  //Display the themrometers in a table
  client->println("<table border=\"1\"> ");
  client->println("<tr>");
  client->println("<th>Sensor</th>");
  client->println("<th>Current Temp C</th>");          
  client->println("<th>Target Temp</th>");
  client->println("<th>PID Result</th>");
  client->println("</tr>");
  
  for (byte i=0; i< sensorCount; i++)
  {
    client->print("<tr>");
    
    client->print("<td>");
    client->print(i,DEC);
    client->print("</td>");
    
    client->print("<td>");
    client->print( _tempMgr->getTempC( i ) );
    client->print("</td>");
    
    client->print("<td>");
    client->print( _tempMgr->getTargetTemp( i ) );
    client->print("</td>");

    client->print("<td>");
    client->print( _PID->getValue( i ) );
    client->print("</td>");

    client->println("</tr>");
  };

  client->println("</table>");
  
  client->println("<h5>Heat Power =");
  client->print( _SSR->getPower() );
  client->print("% / ");
  client->print( _SSR->getJiffy() );
  client->println(" j </h5>");
  
  client->print("<h5> Free Memory = ");
  client->print( freeMemory() );
  client->println("</h5>");
  
  client->println("<form name=\"input\" action=\"yournewtemp\" method=\"get\">");
  client->println("New Target Temp: <input type=\"text\" name=\"newTemp\" />");
  client->println("<input type=\"submit\" value=\"Submit\" />");
  client->println("</form>"); 
  
  client->println("</body>");
  client->println("</html>");         
}

void M8_WebServer::doListenForClients( void ) {
  // listen for incoming clients
  Client client = _server->available();
  String clientString;// incoming line of text  
  
  if (client) {
     
    boolean currentLineIsBlank = false;
 
    Serial.print("!");
      
    while (client.connected())
    {
      
      if (client.available())
      {
        char c = client.read();
        
        Serial.print ( c );                    
//          GET /yournewtemp?newTemp=70 HTTP/1.1
//            return from pressing the submit button
//          GET /temp HTTP/1.1
//            request for the temp
//          GET / HTTP/1.1
//            request for the default page

        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank) {
          // send a standard http response header
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: text/html");
          client.println();

          // output the value of each analog input pin
          for (int analogChannel = 0; analogChannel < 6; analogChannel++) {
            client.print("analog input ");
            client.print(analogChannel);
            client.print(" is ");
            client.print(analogRead(analogChannel));
            client.println("<br />");
          }
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

// Just a utility function to nicely format an IP address.
const char* M8_WebServer::ip_to_str(const uint8_t* ipAddr)
{
  static char buf[16];
  sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  return buf;
}

#endif //#ifndef M8_WEB_CPP
