library test;


import 'dart:html';
import 'dart:async';

part 'touch.dart';
WebSocket ws;

outputMsg(String msg) {
  
  print(msg);

}

//standard websocket setup
void initWebSocket([int retrySeconds = 2]) {
  var reconnectScheduled = false;

  outputMsg("Connecting to websocket");
  ws = new WebSocket('ws://127.0.0.1:4040/ws');

  void scheduleReconnect() {
    if (!reconnectScheduled) {
      new Timer(new Duration(milliseconds: 1000 * retrySeconds), () => initWebSocket(retrySeconds * 2));
    }
    reconnectScheduled = true;
  }

  ws.onOpen.listen((e) {
    outputMsg('Connected');
    ws.send('connected');
  });

  ws.onClose.listen((e) {
    outputMsg('Websocket closed, retrying in $retrySeconds seconds');
    scheduleReconnect();
  });

  ws.onError.listen((e) {
    outputMsg("Error connecting to ws");
    scheduleReconnect();
  });

  ws.onMessage.listen((MessageEvent e) {
//    outputMsg('Received message: ${e.data}');
  });
}


//make the game.
var game;

void main() {

  print("started");
  initWebSocket();
  game = new Game();

}

void repaint() {
  game.draw();
}


//object class, unlike server, this one is touchable but otherwise has the same properties
class Box implements Touchable{
  num x;
  num y;
  var color;
  num id;
  bool dragged;
  
  Box rightBuddy = null;
  Box leftBuddy = null;
  
  Box leftNeighbor = null;
  Box rightNeighbor = null; 
  
  Timer dragTimer;
  
  Box(this.id, this.x, this.y, this.color){
    document.onMouseUp.listen((e) => myTouchUp(e));
    dragged= false;
  }
  
  //when this object is dragged, send a 'd' message with id, x, y, color
  sendDrag(num newX, num newY){
    ws.send("d:${id},${newX},${newY},${color}");
  }
  

  bool containsTouch(Contact e) {
    if(e.touchX > x && e.touchX < x + 50){
      if(e.touchY > y && e.touchY < y + 50){
        print("true");
        return true;
      }
    }
  return false;
  }
   
  bool touchDown(Contact e) {
    dragged = true;
//    dragTimer = new Timer.periodic(const Duration(milliseconds : 80), (timer) => sendDrag(e.touchX, e.touchY));
//    print(e.touchX);
    return true;
  }
   
  void touchUp(Contact event) {
    dragged = false;
    dragTimer.cancel();
    ws.send("b:${id}");
    print("touchup ${id}");
  }
  
  //this is same as touchUp but the touch.dart doesn't seem have an error in touchUp
  void myTouchUp(MouseEvent event) {
    try{
      dragTimer.cancel();
    }
    catch(exception){
      
    }
    dragged = false;
    pieceLocation();
    ws.send("b:${id}");
//    print("touchup ${id}");
  }
   
  void touchDrag(Contact e) {
    //since touchUp has issues it impacts touchDrag so have extra bool to makes sure this are being dragged
    if(dragged){
      sendDrag(e.touchX, e.touchY);
      print(e.touchX);
    }
  }
   
  void touchSlide(Contact event) { }
  
  void pieceLocation (){
      //Change 50 to width and hieght 
      if (rightBuddy != null && leftBuddy != null){
              if (rightBuddy.x + 10 >= this.x && rightBuddy.y + 10 >= this.y && rightBuddy.x + 10 <= this.x + 20 && rightBuddy.y + 10 <= this.y + 20){
                    //leftBuddy.rightNeighbor = this;
                    rightBuddy.leftNeighbor = this;
                    this.rightNeighbor = rightBuddy;
                    print ('neighbors!');
                    ws.send("n:${id},right,${rightNeighbor.id}");
                 }
              if (leftBuddy.x + 10 >= this.x && leftBuddy.y + 10 >= this.y && leftBuddy.x + 10 <= this.x + 20 && leftBuddy.y + 10 <= this.y + 20){
                    leftBuddy.rightNeighbor = this;
                    this.leftNeighbor = leftBuddy;
                    print ('neighbors!');
                    ws.send("n:${id},left,${leftNeighbor.id}");
                 }
          }
      if (rightBuddy != null && leftBuddy == null){
          if (rightBuddy.x + 10 >= this.x && rightBuddy.y + 10 >= this.y && rightBuddy.x + 10 <= this.x + 20 && rightBuddy.y + 10 <= this.y + 20){
                this.rightNeighbor = rightBuddy;
                rightBuddy.leftNeighbor = this;
                print ('neighbors!');
                ws.send("n:${id},right,${rightNeighbor.id}");
             }
          }
      if (leftBuddy != null && rightBuddy == null){
              if (leftBuddy.x + 10 >= this.x && leftBuddy.y + 10 >= this.y && leftBuddy.x + 10 <= this.x + 20 && leftBuddy.y + 10 <= this.y + 20){
                    this.leftNeighbor = leftBuddy;
                    leftBuddy.rightNeighbor = this;
                    print ('neighbors!');
                    ws.send("n:${id},left,${leftNeighbor.id}");
                 }
              }
      }
  
}


//client state class, doesn't need update or send state, just need to keep track of objects via updateBox()
class State{
  List<Box> myBoxes;
  TouchLayer tlayer;
  
  State(this.tlayer){
    myBoxes = new List<Box>();
  }
  
  addBox(Box newBox){
    myBoxes.add(newBox);
  }
  
  updateState(){


  }
  
  sendState(){

    
  }
  
  updateBox(num id, num x, num y, String color){
    bool found = false;
    for(Box box in myBoxes){
      if(id == box.id){
        box.x = x;
        box.y = y;
        box.color = color;
        found = true;
          int i = myBoxes.indexOf(box);
                if (i == 0){
                  box.rightBuddy = myBoxes[i + 1];
                }
                if (i == myBoxes.length - 1){
                  box.leftBuddy = myBoxes[i - 1];
                }
                if (i != 0 && i != myBoxes.length - 1) {
                  box.leftBuddy = myBoxes[i - 1];
                  box.rightBuddy = myBoxes[i + 1];
                }
      }
    }
    
    //if new box, create new object and add to touchables
    if(found == false){
      Box temp = new Box(id, x, y, color);
      tlayer.touchables.add(temp);
      myBoxes.add(temp);
    }
    

  }
  
  
  
}


//client game class, allows us to draw images and create touch layers.
class Game {
  
   
  // this is the HTML canvas element
  CanvasElement canvas;
  
  // this object is what you use to draw on the canvas
  CanvasRenderingContext2D ctx;

  // this is for multi-touch or mouse event handling  
  //TouchManager tmanager = new TouchManager();

  // width and height of the canvas
  int width, height;
  
  State myState;
  
  TouchManager tmanager = new TouchManager();
  TouchLayer tlayer = new TouchLayer();
  
  Game() {
    canvas = querySelector("#game");
    ctx = canvas.getContext('2d');
    width = canvas.width;
    height = canvas.height;
    
    tmanager.registerEvents(document.documentElement);
    tmanager.addTouchLayer(tlayer);
    myState = new State(tlayer);
       
    
    // redraw the canvas every 40 milliseconds runs animate function every 40 milliseconds 
    //updating at 15fps for now, will test for lag at 30 fps later
    new Timer.periodic(const Duration(milliseconds : 80), (timer) => animate());
    
  }


/**
 * Animate all of the game objects makes things movie without an event 
 */
  void animate() {
    ws.onMessage.listen((MessageEvent e) {
      handleMsg(e.data);
    });
    draw();
  }
  

/**
 * Draws programming blocks
 */
  void draw() {
    ctx.clearRect(0, 0, width, height);
    for(Box box in myState.myBoxes){
      ctx.fillStyle = box.color;
      ctx.fillRect(box.x, box.y, 50, 50);
    }
    ctx.fillStyle = "yellow";
    ctx.fillRect(0, 0, 50, 50);
  }
  
  //parse incoming messages 
  handleMsg(data){
    //'u' message indicates a state update
    if(data[0] == "u"){
      //split up the message via each object
      List<String> objectsData = data.substring(2).split(";");
      for(String object in objectsData){
        //parse each object data and pass to state.
        List<String> data = object.split(",");
        if(data.length > 3){
          myState.updateBox(num.parse(data[0]), num.parse(data[1]), num.parse(data[2]), data[3]);
        }
      }
    }
  }
}
