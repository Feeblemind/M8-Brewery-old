#ifndef M8_WEB_H
#define M8_WEB_H

//Ethernet includes
#include <SPI.h>
#include <Ethernet.h>
#include <Client.h>
#include <Server.h>
#include <Udp.h>

#include "WProgram.h"
#include "M8_Constants.h"
#include "M8_PID.h"
#include "M8_SSR.h"
#include "M8_TempMgr.h"

class M8_WebServer {

  //Pointer to the server that main holds
  Server *_server;
  
  //Pointers to the PIDs and the SSRs
  M8_PID *_PID;
  M8_SSR *_SSR;
  M8_TempMgr *_tempMgr;
  
  public:
    const char* ip_to_str(const uint8_t* ipAddr);  
    void setupWebServer( Server *server, M8_PID *PID, M8_SSR *SSR, M8_TempMgr *tempMgr );
    void doListenForClients( void );
    
  private:
    void _doServeBasicHeader( Client *client );
    void _doServePage( Client *client );

};

#endif //#ifndef M8_WEB_H
