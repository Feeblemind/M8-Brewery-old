#ifndef M8_TempMgr_cpp
#define M8_TempMgr_cpp

#include "WProgram.h"
#include "M8_TempMgr.h"

//Thermometer includes
#include <OneWire.h>

M8_TempMgr::M8_TempMgr()
{

_addr[0][0] = 0x10;
_addr[0][1] = 0xF3;
_addr[0][2] = 0x08;
_addr[0][3] = 0xB4;
_addr[0][4] = 0x01;
_addr[0][5] = 0x08;
_addr[0][6] = 0x00;
_addr[0][7] = 0xAC; //This is the wired probe

_addr[1][0] = 0x10;
_addr[1][1] = 0xAA;
_addr[1][2] = 0x06;
_addr[1][3] = 0xB4;
_addr[1][4] = 0x01;
_addr[1][5] = 0x08;
_addr[1][6] = 0x00;
_addr[1][7] = 0xB6; //This is the bread board probe

	_nextRead = 0;

	for ( int i=0; i<sensorCount; i++ )
	{
		_temp[i] = 0;
		_targetTemp[i] = 0;
	}
}; 

void M8_TempMgr::setupTempMgr( OneWire *ow )
{
  _owBus = ow;
}

float M8_TempMgr::getError( int sensor ) // Helper function for the PID, returns the error
{
  return ( _targetTemp[ sensor ] - _temp[ sensor ] );
}

boolean M8_TempMgr::update( void ) // Tells this chip to start temp conversion
{
	boolean newData = false;

	// If its time for us to update, then:	
	if ( millis() > _nextRead )
	{
		for ( int i=0; i<sensorCount; i++ )
		{
			// Read the temps in;
			_temp[i] = _getTemperature( _addr[i] );

			// And tell the sensor to work on the next reading
			_writeTimeToScratchpad( _addr[i] );
		}
		newData = true;
		_nextRead = millis() + tempReadDelay;		
	}

	return newData;
};

float M8_TempMgr::getTempC( int sensor )
{
	return _temp[ sensor ];
};

float M8_TempMgr::getTempF( int sensor )
{
	return _c2f(_temp[ sensor ]);
};

float M8_TempMgr::getTargetTemp( int sensor )
{
	return _targetTemp[ sensor ];
};

void M8_TempMgr::setTargetTemp( int sensor, float temp )
{
	_targetTemp[ sensor ] = temp;
};

void M8_TempMgr::_writeTimeToScratchpad(byte* address)
{
  //reset the bus
  _owBus->reset();
  //select our sensor
  _owBus->select(address);
  //CONVERT T function call (44h) which puts the temperature into the scratchpad
  _owBus->write(0x44,1);
  //sleep a second for the write to take place
}

void M8_TempMgr::_readTimeFromScratchpad(byte* address, byte* data) // function to read the temp from the sensors, used by getTemperature;
{
  //reset the bus
  _owBus->reset();
  //select our sensor
  _owBus->select(address);
  //read the scratchpad (BEh)
  _owBus->write(0xBE);
  for (byte i=0;i<9;i++){
    data[i] = _owBus->read();
  }
}

float M8_TempMgr::_getTemperature(byte* address) // Reads the temp from the chip, must be called at least readTempDelay millis() from last update.
{
  int tr;
  byte data[12];
 
  _readTimeFromScratchpad(address,data);
 
  //put in temp all the 8 bits of LSB (least significant byte)
  tr = data[0];    
 
  //check for negative temperature
  if (data[1] > 0x80)
  {
    tr = !tr + 1; //two's complement adjustment
    tr = tr * -1; //flip value negative.
  }
 
  //COUNT PER Celsius degree (10h)
  int cpc = data[7];
  //COUNT REMAIN (0Ch)
  int cr = data[6];
 
  //drop bit 0
  tr = tr >> 1;
 
  //calculate the temperature based on this formula :
  //TEMPERATURE = TEMP READ - 0.25 + (COUNT PER Celsius Degree - COUNT REMAIN)/ (COUNT PER Celsius Degree)
 
  return tr - (float)0.25 + (cpc - cr)/(float)cpc;
}

//fahrenheit to celsius conversion
float M8_TempMgr::_f2c(float val)
{
  float aux = val - 32;
  return (aux * 5 / 9);
}
 
//celsius to fahrenheit conversion
float M8_TempMgr::_c2f(float val)
{
  float aux = (val * 9 / 5);
  return (aux + 32);
}

/*
Proposed functions:
	Scan for sensors
*/ 
#endif //ifndef M8_TempMgr_cpp
