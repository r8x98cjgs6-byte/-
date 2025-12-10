// =========================
// 핀 설정
// =========================
int ledPin = 9;
int buzzerPin = 8;

int tempPin = A0;  // NTC 온도
int lightPin = A1; // LDR 조도

// =========================
// 타이머 관련 변수
// =========================
unsigned long timerStart = 0;
unsigned long timerDuration = 0;
bool timerRunning = false;
bool alarmOn = false;

// =========================
// NTC 파라미터
// =========================
const float Rfixed = 10000.0;     // 고정 저항 10k
const float R0 = 10000.0;         // NTC 25°C 기준 10k
const float B = 3950.0;           // B계수
const float T0 = 298.15;          // 25°C = 298.15K

void setup() {
  Serial.begin(9600);

  pinMode(ledPin, OUTPUT);
  pinMode(buzzerPin, OUTPUT);

  digitalWrite(ledPin, LOW);
  noTone(buzzerPin);
}

void loop() {

  // =========================
  // 센서 읽기
  // =========================
  int tempADC = analogRead(tempPin);
  int lightVal = analogRead(lightPin);

  // 보호(회로 끊기면 ADC=0 → 0으로 나누기 오류 방지)
  if (tempADC <= 0) tempADC = 1;

  // NTC 계산
  float Rntc = Rfixed * (1023.0 / tempADC - 1.0);
  float tempK = 1.0 / ((1.0 / T0) + (1.0 / B) * log(Rntc / R0));
  float tempC = tempK - 273.15;

  // PC로 전송 (섭씨)
  Serial.print(tempC, 2);// 소수점 2자리 (예: 25.50)
  Serial.print(",");        // 조도 시작 마커
  Serial.println(lightVal);   // 조도 값 + 줄바꿈


// =========================
  // 프로세싱에서 보낸 명령 읽기
  // =========================
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim(); // <--- 핵심: 공백 및 줄바꿈 문자 제거

    if (cmd.startsWith("START:")) {
      timerDuration = cmd.substring(6).toInt();
      timerStart = millis();
      timerRunning = true;
      alarmOn = false;

      digitalWrite(ledPin, LOW);
      noTone(buzzerPin);
    }
    
    // trim()을 했으므로 정확히 비교 가능
    if (cmd == "STOP") { 
      timerRunning = false;
      alarmOn = false;

      digitalWrite(ledPin, LOW);
      noTone(buzzerPin);
    }
  }


  // =========================
  // 타이머 동작
  // =========================
  if (timerRunning) {
    if (millis() - timerStart >= timerDuration) {
      timerRunning = false;
      alarmOn = true;
    }
  }


  // =========================
  // 알람
  // =========================
  if (alarmOn) {
    digitalWrite(ledPin, HIGH);
    tone(buzzerPin, 1000);
  }

  delay(200);
}
