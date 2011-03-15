#ifndef M8_SSR_h
#define M8_SSR_h

#include "WProgram.h"

class M8_SSR
{
  byte _pin;
  byte _jiffy;
  
  public:
  
  M8_SSR( );

  void setupSSR( byte pin );

  unsigned int getPower( void );
  
  void setPower( byte power );
  
  unsigned int getJiffy( void );

  void update( void );
    
  private:
  
  void _calcJiffy( byte power );
};

#endif //#ifndef M8_SSR_h
