#ifndef M8_PID_CPP
#define M8_PID_CPP

#include "WProgram.h"
#include "M8_PID.h"

  M8_PID::M8_PID()
  {
    _pGain = 0;
    _iGain = 0;
    _dGain = 0;
    
    _pTerm = 0;
    _iTerm = 0;
    _dTerm = 0;
    
    _iTermMin = 0;
    _iTermMax = 0;
    
    _iTermLimited = true;
      
    _error = 0;
    _iState = 0;
    _dState = 0;
    
    _lastUpdate = 0;
    _updateInterval = 0;
    
    _value = 0;
  };
  
  float M8_PID::getValue( void )
  {
    return _value;
  }
  
  void M8_PID::setupPID( float pGain, float iGain, float dGain, float iTermMin, float iTermMax, unsigned int updateInterval )
  {
    setPGain( pGain );
    setIGain( iGain );
    setDGain( dGain );
    
    _iTermMin = iTermMin;
    _iTermMax = iTermMax;
    
    if ( iTermMin == iTermMax )
    //If they're the same don't use the limit values
      _iTermLimited = false;
      
    _error = 0;
    _iState = 0;
    _dState = 0;
    
    _updateInterval = updateInterval;
  }
  
  void M8_PID::calcPID( float temperature, float error )
  {
    // check to see if our last update wasn't that long ago
    if ( millis() > ( _lastUpdate + _updateInterval ) )
    {
      _error = error;
      
      _pTerm = _calcPTerm();    
      _iTerm = _calcITerm();
      _dTerm = _calcDTerm( temperature );
      
      _value = ( _pTerm + _dTerm + _iTerm );
      
      _lastUpdate = millis();
    }
  }
  
  float M8_PID::getPGain( void )  {    return _pGain;  };
  float M8_PID::getIGain( void )  {    return _iGain;  };
  float M8_PID::getDGain( void )  {    return _dGain;  };

  void M8_PID::setPGain( float pGain )  {    _pGain = pGain;  };
  void M8_PID::setIGain( float iGain )  {    _iGain = iGain;  };
  void M8_PID::setDGain( float dGain )  {    _dGain = dGain;  };
  
  float M8_PID::getPTerm( void )  {    return _pTerm;  };
  float M8_PID::getITerm( void )  {    return _iTerm;  };
  float M8_PID::getDTerm( void )  {    return _dTerm;  };  
  
  void M8_PID::setPTerm( float pTerm )  {    _pTerm = pTerm;  };
  void M8_PID::setITerm( float iTerm )  {    _iTerm = iTerm;  };
  void M8_PID::setDTerm( float dTerm )  {    _dTerm = dTerm;  };
    
  float M8_PID::_calcPTerm( void )
  {
    return ( _pGain * _error );
  }
  
  float M8_PID::_calcITerm( void )
  {
    _iState += _error;
    
    if ( _iTermLimited )
      if ( _iState > _iTermMax )
        _iState = _iTermMax;
      else if ( _iState < _iTermMin )
        _iState = _iTermMin;
      
    return ( _iGain * _iState );
  }
  
  float M8_PID::_calcDTerm( float temp )
  {
    float tempDTerm;
    
    tempDTerm = _dGain * ( _dState - temp );
    
    _dState = temp;
    
    return ( tempDTerm );
  };
#endif //Define M8_PID
