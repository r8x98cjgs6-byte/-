import processing.serial.*;
import processing.net.*; // 웹 서버 기능을 위해 추가

// =========================
// 통신 설정 및 변수
// =========================
Serial myPort;
Server s; // 웹 서버 객체

String receivedData = "T:---,L:---";  // App Inventor 형식(T:xx.xx,L:xxx)으로 저장

void setup() {
  size(400, 200);
 
  // 시리얼 포트 설정
  println(Serial.list());
  // !!! 포트 번호가 Serial.list()[2]가 맞는지 꼭 확인하세요 !!!
  myPort = new Serial(this, Serial.list()[2], 9600);
  myPort.bufferUntil('\n');
 
  // 웹 서버 설정 (App Inventor 요청 수신)
  s = new Server(this, 9600); // App Inventor 블록의 포트(9600)와 일치
  println("Web Server started on port 9600.");
}

void draw() {
  background(0);

  // ===============================
  // 웹 서버 요청 처리 (App Inventor)
  // ===============================
  Client client = s.available();
  if (client != null) {
    String request = client.readStringUntil('\n'); // HTTP 요청의 첫 줄 (GET /cmd?v=...)
    if (request != null) {
      handleRequest(request, client);
    }
  }
 
  // ===============================
  // 화면 표시 (디버깅)
  // ===============================
  fill(255);
  textSize(18);
  text("Received: " + receivedData, 20, 50);
  text("Server Status: Listening on 9600", 20, 80);
  text("Press 1: Start 5 sec timer", 20, 110);
  text("Press 2: Start 10 sec timer", 20, 140);
  text("Press S: Stop alarm", 20, 170);
}


// ===============================
// 아두이노 데이터 수신 (시리얼)
// ===============================
void serialEvent(Serial p) {
  String temp = p.readStringUntil('\n');
  if (temp != null) {
    temp = temp.trim();
   
    // 수정됨: 아두이노가 이미 T:와 L:을 붙여서 보내므로
    // 프로세싱에서는 가공하지 않고 그대로 저장합니다.
    receivedData = temp;
   
    println("Received (Raw): " + temp);
    println("Saved Data: " + receivedData);
  }
}


// ===============================
// HTTP 요청 처리 및 아두이노로 중계
// ===============================
void handleRequest(String request, Client client) {
  request = request.trim();
  println("Received HTTP Request: " + request);
 
  // 1. 명령(cmd) 요청 처리 (Button_start, Button_stop)
  if (request.startsWith("GET /cmd?v=")) {
   
    // URL에서 v= 뒤의 값 (예: START:5000 또는 STOP)을 추출
    int startIdx = request.indexOf("v=") + 2;
    int endIdx = request.indexOf(" ", startIdx);
    if (endIdx == -1) endIdx = request.length();
   
    String commandValue = request.substring(startIdx, endIdx);
   
    // 아두이노에게 시리얼로 명령 전달 (줄바꿈 \n 추가)
    myPort.write(commandValue + "\n");
    println("Forwarded to Arduino: " + commandValue);
   
    // App Inventor에게 HTTP 200 OK 응답
    client.write("HTTP/1.1 200 OK\r\n");
    client.write("Content-Type: text/plain\r\n");
    client.write("\r\n");
    client.write("Command received: " + commandValue);
 
  // 2. 센서 데이터 요청 처리 (Clock1.Timer)
  } else if (request.startsWith("GET /sensor")) {
      // 현재 저장된 센서 데이터(receivedData)를 응답으로 보냄
      client.write("HTTP/1.1 200 OK\r\n");
      client.write("Content-Type: text/plain\r\n");
      client.write("\r\n");
      // App Inventor의 GotText가 파싱할 수 있는 형식으로 전송
      client.write(receivedData);
      println("Sent sensor data: " + receivedData);
     
  } else {
    // 알 수 없는 요청은 404 응답
    client.write("HTTP/1.1 404 Not Found\r\n");
    client.write("\r\n");
  }
 
  client.stop(); // 클라이언트 연결 종료
}


// ===============================
// 키 조작 (기존 기능 유지)
// ===============================
void keyPressed() {
  if (key == '1') {
    myPort.write("START:5000\n");
    println("Send START:5000");
  }

  if (key == '2') {
    myPort.write("START:10000\n");
    println("Send START:10000");
  }

  if (key == 's' || key == 'S') {
    myPort.write("STOP\n");
    println("Send STOP");
  }
}
