import processing.video.*;
import processing.serial.*;

Serial myPort; //Create object from Serial class
String dataFromArduino; //Data received from the serial port

int statusHandset=0;//checks if telephone handset is picked up or set down
int runningNumberDialled, numberDialled;//checks number dialled
boolean reset;

StringList codePostcards = new StringList ("2289", "3217", "4461", "9641", "4366"); //number to be dialled
StringList dialledNumbers;
String dialledNumbersJoined;
boolean [] postcard = new boolean[codePostcards.size()];
boolean postcardOver=true;
boolean postcardPlaying = false;

int sizeText=52;

Movie [] myMovies = new Movie[codePostcards.size()+2]; // TOTAL NUMBER OF FILMS

void setup() 
{
  //size(800, 600);
  fullScreen();
  //frameRate(30);
  //println(Serial.list()); // Prints out the available serial ports.
  //println(Serial.list()[0]);
  myPort = new Serial(this, "/dev/cu.usbmodem14201", 9600);
  myPort.clear();
  
  dialledNumbers = new StringList();
  dialledNumbers.clear();
  
  for (int i=0; i<myMovies.length; i++)
  {
    myMovies[i]= new Movie (this, i+".mp4");
  }
  for (int j=0; j<myMovies.length; j++)
  {
    myMovies[j].play();
    myMovies[j].stop();
  }
  noCursor();
  background(255);
}

void draw() {
  retriveDataFromArduino ();
  playVideos();
  reset = false;
  
  for (int i=0; i<codePostcards.size();i++) {
   if (postcard[codePostcards.index(codePostcards.get(i))]) {
     playPostcards(codePostcards.index(codePostcards.get(i)));
   }
  }
}


void playVideos() {
  //telephone handle settled down
  if (statusHandset==0){
    // Plays the video
    myMovies[0].loop();     
    if (myMovies[0].available()) {
        myMovies[0].read(); // Reads new frames from the movie
    }
    image(myMovies[0], 0, 0, width, height); // Draws the video frame to the canvas
  }
  
  //telephone handle picked up
  if (statusHandset==1) {
    if(dialledNumbers.size()<4) {
      myMovies[1].loop();
      if (myMovies[1].available()) {
          myMovies[1].read(); // Reads new frames from the movie
      }
      image(myMovies[1], 0, 0, width, height); // Draws the video frame to the canvas
    }
    
    //code to display numbers dialled
    textSize(sizeText);
    fill(0, 30, 212);
    if (dialledNumbers.size()>0) {
      for (int k=0; k<dialledNumbers.size(); k++) {
        if (postcardOver) {
        textAlign(RIGHT);
        text(dialledNumbers.get(k), ((width/2)-(sizeText*2))+(k*sizeText), height-(sizeText*2.5));
        }
      }
      
      if (dialledNumbers.size()==4) { //starts to compare the number dialed
        myMovies[1].stop(); //stops video 1
        myMovies[1].jump(0); //rewinds video 1
        postcardOver=false;
    
        for (int i=0; i<codePostcards.size();i++) {
          if(dialledNumbersJoined.equals(codePostcards.get(i))&& !postcardPlaying) { //compares dialled number with numbers on the databae
            postcard[codePostcards.index(codePostcards.get(i))]=true;
            myMovies[codePostcards.index(codePostcards.get(i))+2].play();
            //playPostcards(codePostcards.index(codePostcards.get(i)));
            postcardPlaying=true;
          }
        }
        
        for (int i=0; i<codePostcards.size();i++) {
          if(!dialledNumbersJoined.equals(codePostcards.get(i)) && !postcardPlaying) { //compares dialled number with numbers on the databae
            background(255); //stays like this until handhelpd is put down
            fill(100, 30, 212);
            textAlign(CENTER);
            text("wrong number!", (width/2), (height/2)-(height*0.05));
            text("hang up and dial again!", (width/2), (height/2)+(height*0.05));
          }
        }
      } 
    }
  }
}

void playPostcards(int numberVideoToBePlayed) {
  int indexOfPostcard = numberVideoToBePlayed;
  int offSet = 2; //video number in the array needs to be offsetted to trigger right video
  
  if(postcard[indexOfPostcard] && statusHandset==1) {
    if (myMovies[indexOfPostcard+offSet].available()) {
      myMovies[indexOfPostcard+offSet].read(); // Reads new frames from the movie
     }
    image(myMovies[indexOfPostcard+offSet], 0, 0, width, height);
  }
  if (myMovies[indexOfPostcard+offSet].time() >= myMovies[indexOfPostcard+2].duration()-1) //resets thing when audiovideo postcard is finished
  {
    myMovies[indexOfPostcard+offSet].stop();
    myMovies[indexOfPostcard+offSet].jump(0);
    dialledNumbersJoined="";
    dialledNumbers.clear();
    postcardOver=true;
    postcardPlaying=false;
    postcard[indexOfPostcard]=false;
    println("terminou");
  }
}

void retriveDataFromArduino () {
  String dataFromArduino = myPort.readStringUntil('\n');
  
  if (dataFromArduino != null) {   
    //checks if telephone handset is picked up or set down
    //arduino sends value only if the variable changes
    
    if (dataFromArduino.startsWith("ONOFF:")) {
      //println(dataFromArduino.length());
      char lastChar0 = dataFromArduino.charAt(dataFromArduino.length() - 3); // Get value after "ONOFF:"
      statusHandset = int (lastChar0)-48; //converts ASCII value to the real int
      
      //TELEPHONE HANDSET SET DOWN
      if (statusHandset==0) {
        //General things to reset
        for (int i=1; i<myMovies.length; i++) { //all the videos stop, besides the initial one
          myMovies[i].stop();
          myMovies[i].jump(0);
        }
        for (int i=0; i<codePostcards.size(); i++) { //codePostcards is the StringList of numbers that can be dialled and are assigned to videos
          postcard[i]=false; //postcard is each audiovideo postcard itself, thus, it is not playing (size 5)
        }
        dialledNumbersJoined=""; //String of numbers that are added to the array when dialling is being made
        dialledNumbers.clear();
        postcardOver=true; //postcard checks if any audiovisual postcard is being played or if it has finished. starts with True
        postcardPlaying=false;
      }
      
      //TELEPHONE HANDSET PICKED UP
      if (statusHandset==1) {
        dialledNumbersJoined="";
        dialledNumbers.clear();
        postcardOver=true;
        postcardPlaying=false;
      }
      //println(statusHandset);
    };
    
    //checks numbers dialled
    if (dataFromArduino.startsWith("NUMBER:")) {
      char lastChar1 = dataFromArduino.charAt(dataFromArduino.length() - 3); // Get value after "ONOFF:"
      runningNumberDialled = int (lastChar1)-48; //converts ASCII value to the real int
      //println(numberDialled);
    };
    
    //arduino did reset after dialling
    if (dataFromArduino.startsWith("RESET:")) {
      if(runningNumberDialled!=0){ //avoids the number zero dialled because it messed up everything
        dialledNumbers.append(str(runningNumberDialled)); //adds dialed number to individual positions on a StringList
        String [] tempDialledNumbers = dialledNumbers.toArray(); //transform StringList into an array
        dialledNumbersJoined = join(tempDialledNumbers, ""); //transforms individuals elements of array into a List
        tempDialledNumbers = null; //resets array
        numberDialled=runningNumberDialled; //number just dialed
        runningNumberDialled=0; // reset number for text
      }
      reset = true;
    };
  };
}
