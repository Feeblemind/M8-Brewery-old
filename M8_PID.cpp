#ifndef M8_PID_CPP
#define M8_PID_CPP

#include "WProgram.h"
#include "M8_PID.h"

  M8_PID::M8_PID()
  {
    for ( byte i=0; i< sensorCount; i++ )
    {
      _info[ i ]._pGain = 0;
      _info[ i ]._iGain = 0;
      _info[ i ]._dGain = 0;
      
      _info[ i ]._pTerm = 0;
      _info[ i ]._iTerm = 0;
      _info[ i ]._dTerm = 0;
      
      _info[ i ]._iTermMin = 0;
      _info[ i ]._iTermMax = 0;
      
      _info[ i ]._error = 0;
      _info[ i ]._iState = 0;
      _info[ i ]._dState = 0;
      
      _info[ i ]._value = 0;
    }
  };
  
  float M8_PID::getValue( byte sensor )
  {
    return _info[ sensor ]._value;
  }
  
  byte M8_PID::getSSRValue( byte sensor )
  {
    float temp = getValue( sensor );
    
    if ( temp > 100 )
      temp = 100;
    if ( temp < 0 )
      temp = 0;
      
    return temp;
  }
  
  void M8_PID::setupPID( byte sensor, float pGain, float iGain, float dGain, float iTermMin, float iTermMax )
  {
    setPGain( sensor, pGain );
    setIGain( sensor, iGain );
    setDGain( sensor, dGain );
    
    _info[ sensor ]._iTermMin = iTermMin;
    _info[ sensor ]._iTermMax = iTermMax;
          
    _info[ sensor ]._error = 0;
    _info[ sensor ]._iState = 0;
    _info[ sensor ]._dState = 0;
  }
  
  void M8_PID::calcPID( byte sensor, float temperature, float error )
  {
    // check to see if our last update wasn't that long ago
    _info[ sensor ]._error = error;
    
    _info[ sensor ]._pTerm = _calcPTerm( sensor );    
    _info[ sensor ]._iTerm = _calcITerm( sensor );
    _info[ sensor ]._dTerm = _calcDTerm( sensor, temperature );
    
    _info[ sensor ]._value = ( _info[ sensor ]._pTerm + _info[ sensor ]._dTerm + _info[ sensor ]._iTerm );
  }
  
  float M8_PID::getPGain( byte sensor )  {    return _info[ sensor ]._pGain;  };
  float M8_PID::getIGain( byte sensor )  {    return _info[ sensor ]._iGain;  };
  float M8_PID::getDGain( byte sensor )  {    return _info[ sensor ]._dGain;  };

  void M8_PID::setPGain( byte sensor, float pGain )  {    _info[ sensor ]._pGain = pGain;  };
  void M8_PID::setIGain( byte sensor, float iGain )  {    _info[ sensor ]._iGain = iGain;  };
  void M8_PID::setDGain( byte sensor, float dGain )  {    _info[ sensor ]._dGain = dGain;  };
  
  float M8_PID::getPTerm( byte sensor )  {    return _info[ sensor ]._pTerm;  };
  float M8_PID::getITerm( byte sensor )  {    return _info[ sensor ]._iTerm;  };
  float M8_PID::getDTerm( byte sensor )  {    return _info[ sensor ]._dTerm;  };  
  
  void M8_PID::setPTerm( byte sensor, float pTerm )  {    _info[ sensor ]._pTerm = pTerm;  };
  void M8_PID::setITerm( byte sensor, float iTerm )  {    _info[ sensor ]._iTerm = iTerm;  };
  void M8_PID::setDTerm( byte sensor, float dTerm )  {    _info[ sensor ]._dTerm = dTerm;  };
    
  float M8_PID::_calcPTerm( byte sensor )
  {
    return ( _info[ sensor ]._pGain * _info[ sensor ]._error );
  }
  
  float M8_PID::_calcITerm( byte sensor )
  {
    _info[ sensor ]._iState += _info[ sensor ]._error;
    
    if ( _iTermLimited( sensor ) )
      if ( _info[ sensor ]._iState > _info[ sensor ]._iTermMax )
        _info[ sensor ]._iState = _info[ sensor ]._iTermMax;
      else if ( _info[ sensor ]._iState < _info[ sensor ]._iTermMin )
        _info[ sensor ]._iState = _info[ sensor ]._iTermMin;
      
    return ( _info[ sensor ]._iGain * _info[ sensor ]._iState );
  }
  
  float M8_PID::_calcDTerm( byte sensor, float temp )
  {
    float tempDTerm;
    
    tempDTerm = _info[ sensor ]._dGain * ( _info[ sensor ]._dState - temp );
    
    _info[ sensor ]._dState = temp;
    
    return ( tempDTerm );
  };
  
  boolean M8_PID::_iTermLimited( byte sensor )
  {
    if ( ( _info[ sensor ]._iTermMin == _info[ sensor ]._iTermMax ) ||  //If they're the same don't use the limit values
         ( _info[ sensor ]._iTermMax < _info[ sensor ]._iTermMin ) )    //If they're invald don't limit either
      return false;    
    else
      return true;
  };
#endif //Define M8_PID
