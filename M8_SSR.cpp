#ifndef M8_SSR_cpp
#define M8_SSR_cpp
  
#include "WProgram.h"
#include "M8_SSR.h"

  M8_SSR::M8_SSR( ) 
  {
    _pin = 0;
    _jiffy = 0;    
  }
  
  void M8_SSR::setupSSR( byte pin )
  {
    _pin = pin;
    
    pinMode( _pin, OUTPUT );
  };
  
  unsigned int M8_SSR::getPower( void )
  {
    return int( round( _jiffy * 1.6666 ) );
  };
  
  void M8_SSR::setPower( byte power )
  {
    if ( power > 100 )
      power = 100;
    else if ( power < 0 )
      power = 0;
      
    _calcJiffy(power);
  };
  
  unsigned int M8_SSR::getJiffy( void )
  {
    return _jiffy;
  };
  
  void M8_SSR::update( void )
  {     
    if ( ( millis() % 1000 ) < ( _jiffy * 16.7 ) )
      digitalWrite( _pin, HIGH );
    else
      digitalWrite( _pin, LOW );
  };
  
  void M8_SSR::_calcJiffy( byte power )
  {
    //for each 1.6% power we have one jiffy
    _jiffy = byte( round( power/ 1.666666 ) );
  };  

#endif //#ifndef M8_SSR_cpp
