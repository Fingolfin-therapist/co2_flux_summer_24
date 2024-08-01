/*
 * CO2 Flux Chamber Project
 * Data Acquisition Module Firmware
 * Casey Air Quality Lab
 * Fort Lewis College 
 *
 * Author: Lincoln Scheer
 *
 * This program serves as the data acquisition 
 * software for a dynamic flux chamber control system.
 * 
*/

#include "../firmware.h"

// Enable Subroutines
const bool DATALOG = true;
const bool SAMPLE = true;

const char* LOGFILENAME = "datalog.txt";

// Pin Definitions
#define SD_CS_PIN		4
#define DHT_DATA_A_PIN	3
#define DHT_DATA_B_PIN	2
#define DATA_LED_PIN	8

// I2C Addresses
#define FLOW_ADDR		0x50
#define ELT_ADDR		0x31

// Sensor Globals
DHT dhtA(DHT_DATA_A_PIN, DHT11);
DHT dhtB(DHT_DATA_B_PIN, DHT11);

// Real-Time Clock
RTC_DS1307		rtc;

// SD Card
Sd2Card card;
SdVolume volume;
SdFile root;

// Setup Routine
void setup() {
	
	Serial.begin(115200);	// Serial @ 115200 Baud

	Serial.println("********");

	Wire.begin();			// I2C 2-Wire

	// Init Diagnostic LED
	pinMode(DATA_LED_PIN, OUTPUT);
	
	// RTC Setup
	Serial.print("RTC ... ");
	if (! rtc.begin()) {
		Serial.println("offline");
	} else {
		if (! rtc.isrunning()) {
    		Serial.println("offline");
		} else {
			Serial.println("online");
			//rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
		}
	}

	// SD Card Setup
	Serial.print("SD ... ");
	if (!SD.begin(SD_CS_PIN)) {
		Serial.println("offline");
	} else {
		Serial.println("online");
	}

	// ELT Setup
	Serial.print("ELT ...");
	for (uint8_t t=0; t<2; t++) {
		tcaselect(t);
		for (uint8_t addr = 0; addr<=127; addr++) {
			if (addr == TCAADDR) continue;
			Wire.beginTransmission(addr);
			if (!Wire.endTransmission()) {
				if (addr == ELT_ADDR) {
					Serial.print(" port ");
					Serial.print(t);
					
				}
			}
		}
		/* Wakup Sensor & Clear
		Wire.beginTransmission(ELT_ADDR);
		Wire.write('W');
		Wire.endTransmission();
		delay(6000);
		Wire.beginTransmission(ELT_ADDR);
		Wire.write('C');
		Wire.endTransmission();
		delay(6000);
		*/
	}
	Serial.println();
	
	// DHT Setup
	Serial.print("DHT11 ... ");
	dhtA.begin();
	dhtB.begin();
	Serial.println("online");

	Serial.println("--------");

}


// Sampling Routine
void loop() {

	// Sampling Interval (ms)
	unsigned int interval = 3000;

	// Data Output Setup
		String date = "";
		String data = "";
		String delim = ",";

	if (SAMPLE) {
		// Sampling Indicator On
		digitalWrite(DATA_LED_PIN, HIGH);

		// Add Date
		DateTime now = rtc.now();
		//date += now.timestamp();
		date += String(millis());
		
		// To hold sensor values
		int co2A, co2B;
		float tempA, humidA, tempB, humidB;
		float flow;

		// Flow Sensor - Transmit Read Flow Command to Sensor
		Wire.beginTransmission(FLOW_ADDR);
		Wire.write(0x00);
		Wire.write(0x3A);
		Wire.endTransmission(false);

		// Flow Sensor - Wait for Response
		delay(2); // 2ms Delay (Sensor Response Time)
		uint8_t Readflow[6];
		Wire.requestFrom(FLOW_ADDR, 6);
		for (int i = 0; i < 6; i++) {
			Readflow[i] = Wire.read();
		}

		// Flow Sensor - Bitshift to Avoid CRC
		long Flow = (long)Readflow[0] << 24;
		Flow += (long)Readflow[1] << 16; 
		Flow += (long)Readflow[3] << 8;
		Flow += (long)Readflow[4]; // bytes [2] and [3] are neglected as they consist CRC 

		// Flow Sensor - Flow in Decimal
		float flowDec = (float) Flow / 1000;
		flow = flowDec;

		// CO2 Sensor - Read ELT
		tcaselect(1);
		co2A = getS300CO2();
		tcaselect(0);
		co2B = getS300CO2();

		// CO2 Sensor - Detect Errors
		if(co2A == 0 || co2A == 64537)
			co2A = -999;
		if(co2B == 0 || co2B == 64537)	
			co2B = -999;

		// Temp. & Humid. - Read DHT
		int readData = dhtA.read(DHT_DATA_A_PIN);
		tempA = dhtA.readTemperature();
		humidA = dhtA.readHumidity();
		readData = dhtB.read(DHT_DATA_B_PIN);
		tempB = dhtB.readTemperature();
		humidB = dhtB.readHumidity();

		// Format Ouput, mark invalid data as -999
		data += date;
		data += delim;

		data += flow;
		data += delim;

		data += String(co2A);
		data += delim;

		if (isnan(tempA)) {
			data += "-999";
		} else {
			data += String(tempA);
		} 
		data += delim;

		if (isnan(humidA)) {
			data += "-999";
		} else {
			data += String(humidA);
		}
		data += delim;

		data += String(co2B);
		data += delim;

		if (isnan(tempB)) {
			data += "-999";
		} else {
			data += String(tempB);
		} 
		data += delim;

		if (isnan(humidB)) {
			data += "-999";
		} else {
			data += String(humidB);
		}
		data += delim;

	}

	// Data Sampling Indicator Off
	digitalWrite(DATA_LED_PIN, LOW);
		
	
	if (DATALOG) {
		// Data logging
		Serial.print("data -> ");

		File file = SD.open(LOGFILENAME, FILE_WRITE);
		if (file) {
			
			Serial.print(LOGFILENAME);
			file.println(data);
			// close the file:	
			
			Serial.println(" (complete)");
		} else {
			// if the file didn't open, print an error:
			Serial.println(" (fail)");
			digitalWrite(DATA_LED_PIN, LOW);
			delay(50);
			digitalWrite(DATA_LED_PIN, HIGH);
			delay(50);
			digitalWrite(DATA_LED_PIN, LOW);
			delay(50);
			digitalWrite(DATA_LED_PIN, HIGH);
			delay(50);
			digitalWrite(DATA_LED_PIN, LOW);
			delay(50);
			digitalWrite(DATA_LED_PIN, HIGH);
			delay(50);
			digitalWrite(DATA_LED_PIN, LOW);
		}
		file.close();

	} else {
		Serial.println(data);
	}
	delay(interval);

}
