#ifndef M8_TempMgr_h
#define M8_TempMgr_h

#include "WProgram.h"

//Thermometer includes
#include <OneWire.h>

#define sensorCount        2 // The number of sensors on the bus
#define oneWirePin         5 // The pin the onewire bus is on.
#define tempReadDelay      1000 // number of millis() to delay after request for temp read.

class M8_TempMgr {  
  
	OneWire  *_owBus;  // The buss the temp sensors are on

	unsigned long _nextRead; // When was the last temp update.

        byte _addr[sensorCount][8];

	float _temp[sensorCount]; // The temps we read in
	float _targetTemp[ sensorCount ]; // The target temps we are trying to get for each sensor

	public:
		M8_TempMgr(); //Default constructor

                void setupTempMgr( OneWire *ow );

		boolean update( void ); // Tells this chip to start temp conversion

		float getTempC( int sensor );
		float getTempF( int sensor );

                float getError( int sensor );

		float getTargetTemp( int sensor );
		void setTargetTemp( int sensor, float temp );

	private:
		void _writeTimeToScratchpad(byte* address); // Function to tell the temp sensors to stat conversion
		void _readTimeFromScratchpad(byte* address, byte* data); // function to read the temp from the sensors, used by getTemperature;

		float _getTemperature(byte* address); // Reads the temp from the chip, must be called at least readTempDelay millis() from last update.

		float _f2c(float val);		//fahrenheit to celsius conversion
		float _c2f(float val);		//celsius to fahrenheit conversion

/*
Proposed functions:
	Scan for sensors
*/ 
};
#endif //ifndef M8_TempMgr_h
