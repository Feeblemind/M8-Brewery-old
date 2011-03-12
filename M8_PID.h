#ifndef PIDClass_h
#define PIDClass_h

#include "WProgram.h"

class M8_PID
{
  float _pGain;
  float _iGain;
  float _dGain;

  float _pTerm;
  float _iTerm;
  float _dTerm;
  
  float _error;
  
  float _iState;
  float _dState;
  
  boolean _iTermLimited;
  float _iTermMax;
  float _iTermMin;

  unsigned int _lastUpdate;
  unsigned int _updateInterval;
  
  float _value;

  public :

	  M8_PID();
  
	  float getValue( void );
  
	  void setupPID( float pGain, float iGain, float dGain, float iTermMin, float iTermMax, unsigned int updateInterval );
  
	  void calcPID( float temperature, float error );
  
	  float getPGain( void );
	  float getIGain( void );
	  float getDGain( void );

	  void setPGain( float pGain );
	  void setIGain( float iGain );
	  void setDGain( float dGain );
  
	  float getPTerm( void );
	  float getITerm( void );
	  float getDTerm( void );
  
	  void setPTerm( float pTerm );
	  void setITerm( float iTerm );
	  void setDTerm( float dTerm );
  
  
  private :
  
	  float _calcPTerm( void );  
	  float _calcITerm( void );  
  	  float _calcDTerm( float temp );
};
#endif // ifndef PIDClass_h
