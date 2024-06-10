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
 * This program includes software developed by the Hannigan Lab at CU
 * Boulder for the AQIQ Y-Pod Air Quality Analyzer.
 * 
*/

// SETTINGS ===================================

const bool DATALOG = true;
const char* LOGFILENAME = "data.txt";

const bool SAMPLE = true;
const bool PUMP_TRIG = false;

// ============================================


// DAQ Header
#include "DAQ.h"

// Pin Definitions
#define SD_CS_PIN		10
#define LCD_RS_PIN		7
#define LCD_EN_PIN		6
#define LCD_D4_PIN		14
#define LCD_D5_PIN		15
#define LCD_D6_PIN		16
#define LCD_D7_PIN		17
#define DHT_DATA_A_PIN	3
#define DHT_DATA_B_PIN	2
#define DATA_LED_PIN	8
#define PUMP_LED_PIN	9
#define PUMP_TRIG_PIN	5

// I2C Addresses
#define FLOW_ADDR		0x50
#define ELT_ADDR		0x31

// Sensor Globals
DHT dhtA(DHT_DATA_A_PIN, DHT11);
DHT dhtB(DHT_DATA_B_PIN, DHT11);

// Peripheral Globals
RTC_DS1307		rtc;
LiquidCrystal 	lcd(LCD_RS_PIN, LCD_EN_PIN, LCD_D4_PIN, LCD_D5_PIN, LCD_D6_PIN, LCD_D7_PIN);

// SD Card
//SdFat sd;
//SdFile file;
Sd2Card card;
SdVolume volume;
SdFile root;

// Setup Routine
void setup() {
	// Init Communication Channels
	Serial.begin(115200);

	float voltage = analogRead(A5);
	Serial.println(voltage);

	//Serial.println("\n\nStarting CO2 Flux DAQ...");
	Wire.begin();
	lcd.begin(16, 2);
	pinMode(DATA_LED_PIN, OUTPUT);
	pinMode(PUMP_LED_PIN, OUTPUT);

	// Display Init Message
	lcd.setCursor(0, 0);
	lcd.print("  Initializing  ");
	lcd.setCursor(0, 1);
	lcd.print("  CO2 Flux DAQ  ");

	// GPIO Output Setup
	pinMode(PUMP_TRIG_PIN, OUTPUT);
	pinMode(SD_CS_PIN, OUTPUT);
	
	// RTC Setup
	//Serial.print("\tRTC:\t");
	if (! rtc.begin()) {
		//Serial.println("\t\toffline");
	} else {
		//if (! rtc.isrunning()) {
    		//Serial.println("\t\toffline");
		//} else {
			//Serial.println("\t\tonline");
			//rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
		//}
	}

	Serial.print("\nInitializing SD card...");

  // we'll use the initialization code from the utility libraries
  // since we're just testing if the card is working!
  if (!card.init(SPI_HALF_SPEED, SD_CS_PIN)) {
    Serial.println("initialization failed. Things to check:");
    Serial.println("* is a card inserted?");
    Serial.println("* is your wiring correct?");
    Serial.println("* did you change the chipSelect pin to match your shield or module?");
    Serial.println("Note: press reset button on the board and reopen this Serial Monitor after fixing your issue!");
    while (1);
  } else {
    Serial.println("Wiring is correct and a card is present.");
  }

  // print the type of card
  Serial.println();
  Serial.print("Card type:         ");
  switch (card.type()) {
    case SD_CARD_TYPE_SD1:
      Serial.println("SD1");
      break;
    case SD_CARD_TYPE_SD2:
      Serial.println("SD2");
      break;
    case SD_CARD_TYPE_SDHC:
      Serial.println("SDHC");
      break;
    default:
      Serial.println("Unknown");
  }


	// SD Card Setup
	//Serial.println("\t- Micro-SD:\t");
	if (!SD.begin(SD_CS_PIN)) {
		//Serial.println("\t\toffline");
	} else {
		//Serial.println("\t\tonline");
	}

	// ELT Setup
	//Serial.println("\t- ELT CO2:\t");
	for (uint8_t t=0; t<2; t++) {
		tcaselect(t);
		for (uint8_t addr = 0; addr<=127; addr++) {
			if (addr == TCAADDR) continue;
			Wire.beginTransmission(addr);
			if (!Wire.endTransmission()) {
				if (addr == ELT_ADDR) {
					//Serial.print("\t\tonline - port ");
					//Serial.println(t);
				}
			}
		}
	}
	
	// DHT Setup
	//Serial.println("\t- DHT11:\t");
	dhtA.begin();
	dhtB.begin();
	//Serial.println("\t\tonline");

	// Display Sampling Message
	//lcd.setCursor(0, 0);
	//lcd.print("    Sampling    ");
	//lcd.setCursor(0, 1);
	//lcd.print("      Data      ");
	//Serial.println("\n\n================================");
	//Serial.println("====      Sampling Data     ====");
	//Serial.println("================================\n");

	if (PUMP_TRIG) {
	// Turn Pump On

		digitalWrite(PUMP_LED_PIN, HIGH);
		digitalWrite(PUMP_TRIG_PIN, HIGH);
	} else {
		digitalWrite(PUMP_LED_PIN, LOW);
		digitalWrite(PUMP_TRIG_PIN, LOW);
	}
}


// Sampling Routine
void loop() {

	// Sampling Interval (ms)
	unsigned int interval = 5000;

	// Data Output Setup
		String date = "";
		String data = "";
		String delim = ",";

	if (SAMPLE) {
		// Sampling Indicator On
		digitalWrite(DATA_LED_PIN, HIGH);

		// Add Date
		DateTime now = rtc.now();
		date += now.timestamp();
		
		// To hold sensor values
		unsigned int co2A, co2B;
		float tempA, humidA, tempB, humidB;
		float flow;

		// Transmit Read Flow Command to Sensor
		Wire.beginTransmission(FLOW_ADDR);
		Wire.write(0x00);
		Wire.write(0x3A);
		Wire.endTransmission(false);
		
		// 2ms Delay (Sensor Response Time)
		delay(2);
		uint8_t Readflow[6];

		// Read Data from Sensor
		Wire.requestFrom(FLOW_ADDR, 6);
		for (int i = 0; i < 6; i++) {
			Readflow[i] = Wire.read();
		}
		
		// Bitshift to Avoid CRC
		long Flow = (long)Readflow[0] << 24;
		Flow += (long)Readflow[1] << 16; 
		Flow += (long)Readflow[3] << 8;
		Flow += (long)Readflow[4]; // bytes [2] and [3] are neglected as they consist CRC 

		// Flow in Decimal
		float flowDec = (float) Flow / 1000;
		flow = flowDec;

		// Read ELT
		tcaselect(1);
		co2A = getS300CO2();
		tcaselect(0);
		co2B = getS300CO2();

		if(co2A == 0)
			co2A = -999;
		if(co2B == 0)	
			co2B = -999;

		// Read DHT
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

		// Report Sensor Values to lcd
		lcd.clear();
		lcd.setCursor(0, 0);
		lcd.print(co2A);
		lcd.setCursor(5, 0);
		lcd.print(String(tempA));
		lcd.setCursor(12, 0);
		lcd.print(String(humidA));
		lcd.setCursor(0, 1);
		lcd.print(co2B);
		lcd.setCursor(5, 1);
		lcd.print(String(tempB));
		lcd.setCursor(12, 1);
		lcd.print(String(humidB));
	}

	// Data Sampling Indicator Off
	digitalWrite(DATA_LED_PIN, LOW);
		
	
	if (DATALOG) {
		// Data logging
		Serial.print("Saving Data...");

		File file = SD.open(LOGFILENAME, FILE_WRITE);
		if (file) {
			Serial.print("Writing to " + String(LOGFILENAME)  + "...");
			file.println(data);
			// close the file:	
			
			Serial.println("done.");
		} else {
			// if the file didn't open, print an error:
			Serial.println("error opening ");
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

