const int pulsePin = 2;          // Pin connected to the pulse wire
int pulseCount = 0;              // Counter for pulses
unsigned long lastPulseTime = 0; // Track the time of the last pulse

int pinAuscultador = 4; //pin to verify if telephone handset is picked up or set down 
boolean leituraAuscultador=false; //true telephone handset picked up, false telephone handset set down;
boolean leituraAuscultadorPrev = true; //variable to store changes;

int pinProntoAMarcar = 7; //pin to verify if user has moved dial but not yet released it
boolean prontoAMarcar; // true dialing going up, false dial is realeased on counting is being done;

int numeroDiscado=0; //number dialed

boolean resetTudo=false; //reset readings

void setup() {
  Serial.begin(9600);
  
  pinMode(pulsePin, INPUT);
  pinMode(pinAuscultador, INPUT);
  pinMode(pinProntoAMarcar, INPUT);
  
  attachInterrupt(digitalPinToInterrupt(pulsePin), countPulse, FALLING);
}

void loop() {
  
  leituraAuscultador = digitalRead(pinAuscultador);

  //to send Serial message once per change (picked up vs set down)
  if(leituraAuscultador!=leituraAuscultadorPrev) {    
    leituraAuscultadorPrev = leituraAuscultador;
    Serial.print("ONOFF:");
    Serial.println(leituraAuscultador);
  }
  
  prontoAMarcar = digitalRead(pinProntoAMarcar);
  //Serial.println(prontoAMarcar);

  //handheld picked up
  if(leituraAuscultador) {

    if(prontoAMarcar) {
       // Check if dialing has finished (no pulses for a while)
      if (pulseCount > 0 && millis() - lastPulseTime > 70) {
        
        // Determine the dialed number
        numeroDiscado = numeroDiscado + pulseCount;
        if (numeroDiscado== 10) {
          numeroDiscado=0;
        }
        Serial.print("NUMBER:");
        Serial.println(numeroDiscado);

        // Reset pulse count for next number
        pulseCount = 0;
      }
    }

    //resets values after 200 ms passed since dialing has been done 
    if(!prontoAMarcar && millis() - lastPulseTime > 200) {
        if(resetTudo) {
          Serial.print("RESET:");
          Serial.println(resetTudo);
          pulseCount = 0;
          numeroDiscado=0;
          resetTudo=false;
        }
    }
  }

  delay(10);
}

// Interrupt function to count pulses
void countPulse() {
  // Debounce: make sure at least 50 ms have passed since the last pulse
  if (millis() - lastPulseTime > 20) {
    pulseCount++;
    lastPulseTime = millis();
    resetTudo=true;
  }
}
