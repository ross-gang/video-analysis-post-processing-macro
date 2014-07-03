/*
The MIT License (MIT)

Copyright (c) 2014 Nicholas M. Schneider

Permission is hereby granted, free of charge, to any person 
obtaining a copy of this software and associated documentation 
files (the "Software"), to deal in the Software without 
restriction, including without limitation the rights to 
use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons 
to whom the Software is furnished to do so, subject to the 
following conditions: The above copyright notice and this 
permission notice shall be included in all copies or substantial 
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
EXPRESS OR  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
OTHER DEALINGS IN THE SOFTWARE.

*/



// This set of macros allows one to save the (x,y) locations of 
//    n number of points in a txt file (tab delineated)
//
// The user will be prompted for options after running the 
//    initialization macro [1]
//
// If stabilization is selected the macro adjusts xy Translations
//    and adjusts canvas size.



// Global Variables to Carry Around
var stabilize = 0; 		//Default: NO - Flag to run stabilzation
var pointsPerSlice = 3; //Default: 3 
var filePath = "";		//Default: NONE
var dataStored = 0;     //Default: FALSE - Flag about data write success
var separator = "\t";	//Default: tab - choose separator (tab, ",", etc) 


//Initialize by Asking What the user wants to do
macro "Initialize [1]" {

	// Ask User if they want to stabilize, and then ask how many points per slice to record
	stabilize = getBoolean("Do you want to stabilize this video?");

	if (stabilize == 1) {
		msg = "How many points per slice?\n\nNote: \n  1. Always select in the same order \n  2) The First point will be used to stabilize";
	} else {
		msg = "How many points per slice?\n\nNote: \n  1. Always select in the same order";
	}
	pointsPerSlice = getNumber(msg,3);

	// Create New File to save raw points data
	file = File.open("");
	fileDirectory = File.directory();
	fileName = File.name();
	filePath = fileDirectory + fileName;
	// Add headings
	data = "Frame";
	for (i = 0; i < pointsPerSlice; i++ ){
		data = data + separator + "X" + d2s(i,0) + separator + "Y" + d2s(i,0) ;
    }
    File.append(data,filePath);

	// Use log to document what is happening... comment out if annoying
	print("\\Clear");
	print("Points to record each slice: "+pointsPerSlice);
	if (stabilize == 1) {
		print("Stabilize? -- YES");
	} else {
		print("Stabilize? -- NO");
	}
	print("Save Location: "+filePath);
	print(data);

}



// Record data and advance
macro "Record Selection [a]" {
	if (stabilize == 1){

    	getSelectionCoordinates(x,y);
		if (dataStored == 0 && x.length == pointsPerSlice) {
			run("writeToFile");

			//Unwrap to put first point in roiManager
			
			makePoint(x[0],y[0]);
			roiManager("add"); 

			if (dataStored == 1) {
				
				if (getSliceNumber < nSlices) {
					dataStored = 0; //Reset Flag
					run("Next Slice [>]");
				} else {
					print("All Done!"); 
				}
				
			}
		} else {
			print("Wrong Number of Points! Plese Select "+d2s(pointsPerSlice,0)+" points. \n This is what you defined at start... If this is wrong, restart.");
		}

    	if (roiManager("count") >= nSlices)
			run("movieStabilize");
    	
	} else {
		if (dataStored == 0) {
			run("writeToFile");
			if (dataStored == 1) {
				
				if (getSliceNumber < nSlices) {
					dataStored = 0; //Reset Flag
					run("Next Slice [>]");
				} else {
					print("All Done!"); 
				}
				
			}
		}
	}   
  }

//Write To File Macro
macro "writeToFile" {
	getSelectionCoordinates(x, y);
	sliceNumber = getSliceNumber();
	data = d2s(sliceNumber,0);

	if( x.length == pointsPerSlice) {
    	for (i = 0; i < pointsPerSlice; i++ ){
        		data = data + separator + d2s(x[i],0) + separator + d2s(y[i],0) ;
    		}
     	}

		File.append(data,filePath);
		dataStored = 1;
     	print(data);
     	
	} else {
		print("Wrong Number of Points! Plese Select "+d2s(pointsPerSlice,0)+" points. \n This is what you defined at start... If this is wrong, restart.");
	}
	
}







//Movie Stabilization Macro
macro "movieStabilize" {
     // Get Reference Location
     roiManager("select", 0);
     run("Measure");
     xStart = getResult("X");
     yStart = getResult("Y");

     // Get Video Length 
     numberOfImages = roiManager("count");

     // Image Size 
     imageWidth = getWidth();
     imageHeight = getHeight();

     // Define Arrays of how far to translate
     xTranslation = newArray(numberOfImages);
     yTranslation = newArray(numberOfImages);

     //Track largest movement to calculate new canvas size
     xMaxTranslation = 0;
     xMinTranslation = 0;
     yMaxTranslation = 0;
     yMinTranslation = 0;

     // Loop over selected Points
     for (i = 0; i < numberOfImages; i++) {
        roiManager("select", i);
     	run("Measure");
     	xPosition = getResult("X");
     	yPosition = getResult("Y");
     	xTranslation[i] = xStart - xPosition;
     	yTranslation[i] = yStart - yPosition;

     	if (xTranslation[i] > xMaxTranslation) {
 		xMaxTranslation = xTranslation[i];
 	} else if  (xTranslation[i] < xMinTranslation) {
 		xMinTranslation = xTranslation[i];
 	}

 	
 	if (yTranslation[i] > yMaxTranslation) {
 		yMaxTranslation = yTranslation[i];
 	} else if  (yTranslation[i] < yMinTranslation) {
 		yMinTranslation = yTranslation[i];
 	}
     	
     }
     
     // Canvas and translation constants
     if(xMaxTranslation > abs(xMinTranslation)) {
     	xMattedBy = xMaxTranslation; 
     } else {
     	xMattedBy = abs(xMinTranslation);
     }
     
     if(yMaxTranslation > abs(yMinTranslation)) {
     	yMattedBy = yMaxTranslation; 
     } else {
     	yMattedBy = abs(yMinTranslation);
     }
     imageWidth = imageWidth + 2 * xMattedBy + 20 ;
     imageHeight = imageHeight + 2 * yMattedBy + 20 ;


     setSlice(1);
     run("Canvas Size...", "width="+imageWidth+" height="+imageHeight+" position=Center zero");

     for (i = 0; i < numberOfImages; i++) {
  	run("Translate...", "x="+xTranslation[i]+" y="+yTranslation[i]+" interpolation=None slice");
   	run("Next Slice [>]");
     }

     f = File.open(""); // display file open dialog
     for (i = 0; i < numberOfImages; i++ ){
     	if ( i < numberOfImages){
           print(f, d2s(xTranslation[i],0)+"  \t"+d2s(yTranslation[i],0) + " \n");
     	} else if (i == numberOfImages-1) {
     	   print(f, d2s(xTranslation[i],0)+"  \t"+d2s(yTranslation[i],0)+"");
     	} // Dont print a return on the last line
     }
}



//Stabilize from file
macro "movieStabilizeFromFile" {
  // Image Size 
  imageWidth = getWidth();
  imageHeight = getHeight();

  // Pull from File
  lines = split(File.openAsString(""), "\n");
  length = lines.length;
  xTranslation = newArray(length);
  yTranslation = newArray(length);
  
  //Track largest movement to calculate new canvas size
  xMaxTranslation = 0;
  xMinTranslation = 0;
  yMaxTranslation = 0;
  yMinTranslation = 0;

  
  for (i = 0; i < length; i++) {
  	// Extract xy Translations from txt file
	xy = split(lines[i], ",\t ");
 	xTranslation[i] = parseFloat(xy[0]);
 	yTranslation[i] = parseFloat(xy[1]);
 	
 	if (xTranslation[i] > xMaxTranslation) {
 		xMaxTranslation = xTranslation[i];
 	} else if  (xTranslation[i] < xMinTranslation) {
 		xMinTranslation = xTranslation[i];
 	}

 	
 	if (yTranslation[i] > yMaxTranslation) {
 		yMaxTranslation = yTranslation[i];
 	} else if  (yTranslation[i] < yMinTranslation) {
 		yMinTranslation = yTranslation[i];
 	}
  }

     // Canvas and translation constants
     if(xMaxTranslation > abs(xMinTranslation)) {
     	xMattedBy = xMaxTranslation; 
     } else {
     	xMattedBy = abs(xMinTranslation);
     }
     
     if(yMaxTranslation > abs(yMinTranslation)) {
     	yMattedBy = yMaxTranslation; 
     } else {
     	yMattedBy = abs(yMinTranslation);
     }
     imageWidth = imageWidth + 2 * xMattedBy + 20;
     imageHeight = imageHeight + 2 * yMattedBy + 20;
	

     setSlice(1);
     run("Canvas Size...", "width="+imageWidth+" height="+imageHeight+" position=Center zero");


     for (i = 0; i < length; i++) {
  	run("Translate...", "x="+xTranslation[i]+" y="+yTranslation[i]+" interpolation=None slice");
   	run("Next Slice [>]");
     }
}
