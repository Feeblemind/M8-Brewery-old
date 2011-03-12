#ifndef M8_SSR_h
#define M8_SSR_h

#include "WProgram.h"

class M8_SSR
{
  unsigned int _pin;
  unsigned int _jiffy;
  
  public:
  
  M8_SSR( );

  void setupSSR( unsigned int pin );

  unsigned int getPower( void );
  
  void setPower( int power );
  
  unsigned int getJiffy( void );

  void update( void );
    
  private:
  
  void _calcJiffy( unsigned int power );
};

#endif //#ifndef M8_SSR_h
