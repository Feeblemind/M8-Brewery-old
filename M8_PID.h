#ifndef PIDClass_h
#define PIDClass_h

#include "WProgram.h"
#include "M8_Constants.h"

struct M8_PID_Info
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
  
  float _iTermMax;
  float _iTermMin;
  
  float _value;
};

class M8_PID
{

  M8_PID_Info _info[ sensorCount ];

  public :

	  M8_PID();
  
	  float getValue( byte sensor );
          byte getSSRValue( byte sensor );
  
	  void setupPID( byte sensor, float pGain, float iGain, float dGain, float iTermMin, float iTermMax );
  
	  void calcPID( byte sensor, float temperature, float error );
  
	  float getPGain( byte sensor );
	  float getIGain( byte sensor );
	  float getDGain( byte sensor );

	  void setPGain( byte sensor, float pGain );
	  void setIGain( byte sensor, float iGain );
	  void setDGain( byte sensor, float dGain );
  
	  float getPTerm( byte sensor );
	  float getITerm( byte sensor );
	  float getDTerm( byte sensor );
  
	  void setPTerm( byte sensor, float pTerm );
	  void setITerm( byte sensor, float iTerm );
	  void setDTerm( byte sensor, float dTerm );
    
  private :
  
          boolean _iTermLimited( byte sensor );
	  float _calcPTerm( byte sensor );  
	  float _calcITerm( byte sensor );  
  	  float _calcDTerm( byte sensor, float temp );
};
#endif // ifndef PIDClass_h
