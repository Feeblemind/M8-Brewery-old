#ifndef M8_CONSTANTS_H
#define M8_CONSTANTS_H

#define sensorCount        2 // The number of sensors on the bus
#define oneWirePin         5 // The pin the onewire bus is on.
#define tempReadDelay      1000 // number of millis() to delay after request for temp read.

#define SSRPin             3 //The pin the SSR is on.
#define webPageUpdateTime  5 // in seconds

#define defaultPGain           40
#define defaultIGain           0.01
#define defaultDGain           0

#define defaultIStateMin       0
#define defaultIStateMax       100
#define defaultUpdateInterval  1000

#endif // #ifndef M8_CONSTANTS_H
