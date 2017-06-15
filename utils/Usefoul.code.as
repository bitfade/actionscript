/*

// Edge Detection in ActionScript 3
// Author: Alex Petrescu (alex.petrescu@gmail.com)
// http://www.Kilometer0.com
// Based on techniques from Canny Edge Detection Tutorial at http://www.pages.drexel.edu/~weg22/can_tut.html
// No Usage or Copy Restriction, just let me know if you found it helpful.

stage.align = StageAlign.TOP_LEFT;

var myGausianFilter:ConvolutionFilter = new ConvolutionFilter(5,5,
[ 2,4,5,4,2,
  4,9,12,9,4,
  5,12,15,12,5,
  4,9,12,9,4,
  2,4,5,4,2],115);

// Original Data
var ourData:BitmapData;

// Edge Data
var ourEdgeData:BitmapData

function findEdges(myLinkage:String):void
{	
	var myClass:Class = flash.utils.getDefinitionByName(myLinkage) as Class;
	ourData = new myClass(0,0);
	
	//Apply Smoothing Filter
	ourData.applyFilter(ourData,ourData.rect,new Point(0,0),myGausianFilter);
	
	//Create New Bitmap to hold edge data
	ourEdgeData = new BitmapData(ourData.width, ourData.height, false);
	
	//Loop through original data and calculate edges
	for(var w:int = 0; w<ourData.width; w++)
	{
		for(var h:int = 0; h<ourData.height; h++)
		{
			var pixelValue270:uint = getGray(ourData.getPixel(w-1, h));
			var pixelValue90:uint = getGray(ourData.getPixel(w+1, h));
			
			var pixelValue0:uint = getGray(ourData.getPixel(w, h-1));
			var pixelValue180:uint = getGray(ourData.getPixel(w, h+1));
			
			var pixelValue315:uint = getGray(ourData.getPixel(w-1, h-1));
			var pixelValue45:uint = getGray(ourData.getPixel(w+1, h-1));
			var pixelValue135:uint = getGray(ourData.getPixel(w+1, h+1));
			var pixelValue225:uint = getGray(ourData.getPixel(w-1, h+1));
			
			// Applying the following convolution mask matrix to the pixel
			//    GX        GY  
			// -1, 0, 1   1, 2, 1
			// -2, 0, 2   0, 0, 0
			// -1, 0, 1  -1,-2,-1
			
			var gx:int = (pixelValue45 + (pixelValue90 * 2) + pixelValue135)-(pixelValue315 + (pixelValue270 * 2) + pixelValue225);
			var gy:int = (pixelValue315 + (pixelValue0 * 2) + pixelValue45)-(pixelValue225 + (pixelValue180 * 2 ) + pixelValue135);
						
			var gray:uint = Math.abs(gx) + Math.abs(gy);
			
			// Decrease the grays a little or else its all black and white.
			// You can play with this value to get harder or softer edges.
			gray *= .5;
			
			// Check to see if values aren't our of bounds
			if(gray > 255)
				gray = 255;
				
			if(gray < 0)
				gray = 0;
	
			// Build New Pixel
			var newPixelValue:uint = (gray << 16) + (gray << 8) + (gray);
			
			// Copy New Pixel Into Edge Data Bitmap
			ourEdgeData.setPixel(w,h,newPixelValue);	
		}	
	}
	status_txt.text = "Showing Edges";
	myBMP.bitmapData = ourEdgeData;
	myBMP.scaleX = myBMP.scaleY = 1;
}

var myBMP:Bitmap = new Bitmap(ourData);
container_mc.addChild(myBMP);

stage.addEventListener(MouseEvent.MOUSE_WHEEL,zoomIn);
stage.addEventListener(MouseEvent.CLICK,testImageClicked);

var ourCurrentImage:String = "";
var ourFrameCount:Number = 0;

function callFindEdges(myEvent:Event):void
{
	if(ourFrameCount == 1)
	{
		findEdges(ourCurrentImage);
		stage.removeEventListener(Event.ENTER_FRAME,callFindEdges);
	}
	ourFrameCount = 1;
}

function testImageClicked(myEvent:MouseEvent):void
{
	if(myEvent.target is MovieClip && myEvent.target.name.substring(0,4) == "img_")
	{
		ourCurrentImage = myEvent.target.name.substring(4);
		status_txt.text = "Processing "+ourCurrentImage+"....";
		ourFrameCount = 0;
		stage.addEventListener(Event.ENTER_FRAME,callFindEdges);		
	}
}

function zoomIn(myEvent:MouseEvent):void
{
	if(myEvent.delta < 0)
	{
		myBMP.scaleX = myBMP.scaleY -= .05;
	}
	else
	{
		myBMP.scaleX = myBMP.scaleY += .05;
	}
}

function getGray(pixelValue:uint):uint
{
	var red:uint = (pixelValue >> 16 & 0xFF) * 0.30;
	var green:uint = (pixelValue >> 8 & 0xFF) * 0.59;
	var blue:uint = (pixelValue & 0xFF) * 0.11;

	return (red + green + blue);
}

function switchImage(myEvent:MouseEvent):void
{
	if(myBMP.bitmapData == ourData)
	{
		status_txt.text = "Showing Edges";
		myBMP.bitmapData = ourEdgeData;
	}
	else
	{
		status_txt.text = "Showing Original";
		myBMP.bitmapData = ourData;
	}
	
	myBMP.smoothing = true;
	
}

container_mc.addEventListener(MouseEvent.MOUSE_DOWN, switchImage);
container_mc.addEventListener(MouseEvent.MOUSE_UP, switchImage);

*/