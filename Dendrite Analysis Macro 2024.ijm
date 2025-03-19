//Redone - MARIA IULIANO 2024, based on Bea C. 2018.original macro by Lai Ding at Harvard
//NOTE: length is an estimation. for best results, please generate your own axon/dendrite length for post-processing
// ImageJ initialize
run("Colors...", "foreground=white background=black selection=magenta");
run("Options...", "iterations=1 count=1 black edm=Overwrite");
run("Set Measurements...", "area perimeter area_fraction limit redirect=None decimal=3");
//set raw result folder. rawdir contains multiple subfolders, each subfolder contains multiple raw images
// result folder should be empty.
rawdir=getDirectory("Choose Starting Images Folder");
resultdir=getDirectory("Choose Result Folder");
//variable setup
var greenThreshold, redThreshold, gnoise, rnoise, areapercent, scale, minsize, maxsize, name, noise, gcount, rcount, grcount, rgcount, axonlength, axonflag;
var greenstring, redstring, j, d, greensum, redsum, resultlist, FolderCreate, foldername, redgcount, FO, findex, LabelArray, greenrcount, totalredgcount, CS, nindex, totalgreenrcount, length, axonlength;
// input parameter
run("Set Measurements...", "area perimeter integrated area_fraction limit redirect=None decimal=5");
getdateandtime();
// function, available in ImageJ 1.34n or later.
  parameterinput();

print("Raw_Folder:	"+rawdir);
print("Result_Folder:	"+resultdir+" \n");

print("GreenThreshold	RedThreshold	AreaPercent(%)	PixelScale(um/pixel)	Min_Puncta_Size	Max_Puncta_Size	Green_Prominence	Red_Prominence	Measurement");
print(greenThreshold+"	"+redThreshold+"	"+areapercent+"	"+scale+"	"+minsize+"	"+maxsize+"	"+gnoise+"	"+rnoise+"	"+length+" \n");

print("	Condition	Coverslip	File	GreenPuncta#	RedPuncta#	GR#	RG#	length	G_10um	R_10um	GR_10um	RG_10um 	 	gr_%AreaAvg(counted)	gr_%AreaAvg(total)	gr_totalCounted	rg_%AreaAvg(counted)	rg_%AreaAvg(total)	rg_totalCounted	\n");
folderlist=getFileList(rawdir);
    greensum="Filename,Condition,Coverslip,File,#Puncta,Length,TotalArea,IntDen,RawIntDen,		,Puncta_10um,AvgSize,AvgInt_AU\n";
    redsum="Filename,Condition,Coverslip,File,#Puncta,Length,TotalArea,IntDen,RawIntDen,		,Puncta_10um,AvgSize,AvgInt_AU\n";
	greenstring="Filename,Condition,Coverslip,File,#,Area,Perim,IntDen,RawIntDen\n";
    redstring="Filename,Condition,Coverslip,File,#,Area,Perim,IntDen,RawIntDen\n";

for(f=0;f<folderlist.length;f++) 
    {
    foldername = File.getName(rawdir+folderlist[f]);
    File.makeDirectory(resultdir+foldername);
    rawlist=getFileList(rawdir+foldername);
    filelist=getFileList(rawdir+folderlist[f]);
    resultpath = getFileList(rawdir+folderlist[f]);
    print(folderlist[f]);
    for(d=0;d<filelist.length;d++)
        {
        // initialize :  open file, split channel, name by "red"/"green"/"axon"
        initialize();
        // create green red mask images and roi files
        mask("green");
        mask("red");
        //measure
        measure();
        temptitle = File.getName(rawdir+folderlist[f]);
        }

}
   	File.saveString(greenstring, resultdir+"Green_Individual_Puncta.csv");
    File.saveString(redstring, resultdir+"Red_Individual_Puncta.csv"); 
    File.saveString(greensum, resultdir+"Green_Average Puncta.csv");
    File.saveString(redsum, resultdir+"Red_Average Puncta.csv"); 
    selectWindow("Log");
saveAs("Text", resultdir+"Dendrite_Analysis.csv");
selectWindow("Log"); run("Close");
selectWindow("Results"); run("Close");
selectWindow("ROI Manager"); run("Close");
selectWindow("Summary"); run("Close");
run("Close All");
//the following functions are listed in order of use in the macro
//thresholding parameters are generally the only ones that need changing, but all can be modified
 //print day and time of macro
 
 function getdateandtime() {
     MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
     DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
     getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
     TimeString ="Date: "+DayNames[dayOfWeek]+" ";
     if (dayOfMonth<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+dayOfMonth+"-"+MonthNames[month]+"-"+year+"\nTime: ";
     if (hour<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+hour+":";
     if (minute<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+minute+":";
     if (second<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+second;
       print(TimeString);
  }
 
 //macro parameters including scale, thresholding, etc
  function parameterinput()
    {
    Dialog.create("Parameters");
        Dialog.addNumber("Green Threshold:", 0);
        Dialog.addNumber("Red Threshold:", 0);
        Dialog.addNumber("Area Percent (%):", 25);
        Dialog.addNumber("Pixel Scale (um/pixel):", 0.10048828);
        Dialog.addNumber("Min Puncta Size (pixel):", 10);
        Dialog.addNumber("Max Puncta Size (pixel):", 250);
        Dialog.addNumber("Green Noise tolerance/prominence", 100);
        Dialog.addNumber("Red Noise tolerance/prominence", 100);
        Dialog.addMessage("!!Double check appropriate scaling/expected puncta size/prominence values!!");
    Dialog.show();
    greenThreshold = Dialog.getNumber();
    redThreshold = Dialog.getNumber();
    areapercent = Dialog.getNumber();  
    scale = Dialog.getNumber();  
    minsize = Dialog.getNumber();  
    maxsize = Dialog.getNumber();
    gnoise = Dialog.getNumber();
   	rnoise = Dialog.getNumber();
   	Dialog.create("Measurements");
   	  Dialog.addCheckbox("Length Measurements Available?", 1);
   	  Dialog.show();
   	  length = Dialog.getCheckbox();
	
	  if(length == 1){
		path = File.openDialog("Select a .csv of length/area measurements");
 		Table.open(path);
 		lengthfile= File.name;
	LabelArray=newArray();
	LabelArray=Table.getColumn("Label");
    }
    }
    
//this function opens the appropriate image from the appropriate folder in the raw data folder
//gets the name, standardizes the properties of the image, splits the channels and discards the blue channel as "axon" to be saved elsewhere
function initialize()
 {
    open(rawdir+foldername+File.separator+rawlist[d]);
    name=getInfo("image.filename");
    nindex=indexOf(name, "CS");
    CS=substring(name,nindex+2,nindex+3);
    findex=indexOf(name, "_F");
    FO=substring(name,findex+2,findex+4);
   
   
  if(length == 1){
  	nameindex=lastIndexOf(name, ".tif");
  	newname=substring(name, 0, nameindex);
  	for (i = 0; i < lengthOf(LabelArray); i++) {
        if (startsWith(LabelArray[i],newname)) {
           axonlength=Table.get("Length", i);
        }
  }
  }
    roiManager("reset");
    getDimensions(width, height, channels, slices, frames);
    run("Properties...", "channels=3 slices=1 frames=1 unit=um pixel_width="+scale+" pixel_height="+scale+" voxel_depth=1");
    run("Split Channels");
    rename("axon");
    selectImage("C1-"+name); 
    rename("red");
    selectImage("C2-"+name); 
    rename("green");
 }
//this function creates a mask for the selected color channel (green or red). 
//it takes the threshold indicated in the parameter input, uses it to point out the maxima 
//and then runs "analyze particles" within the specified puncta size, saves the number of puncta as a string, saves the ROI, 
//and saves the mask
function mask(channel)	{
	selectImage(channel);
	if( channel == "green") {
		setThreshold(greenThreshold, 65535);
		run("Find Maxima...", "prominence="+gnoise+" above output=[Segmented Particles]");
		}
	if( channel == "red") {
		setThreshold(redThreshold, 65535);
		run("Find Maxima...", "prominence="+rnoise+" above output=[Segmented Particles]");
		}
//this find the maximum pixel value within the thresholded area in order to segment into separate particles.
//Prominence is a noise tolerance setting, where a maxima can only be 
//Included prominence customixation in 2024, seems 10 is suited for 8bit, 100+ best for 16bit segmentation
	selectWindow(channel+" Segmented");  
	rename(name);
	run("Analyze Particles...", "size="+minsize+"-"+maxsize+" pixel show=Masks summarize add");
		rename("Mask of "+channel+" Segmented");
		selectImage(name);
		rename(channel+" Segmented");
   selectWindow("Mask of "+channel+" Segmented");  
	run("Grays");
	saveAs("Tiff", resultdir+folderlist[f]+name+"_"+channel+"_mask.tif");
	selectWindow(channel);
	run("Clear Results");
	roiManager("Measure");	
	selectWindow("Results");
	
	if( channel == "green" )  {
		for (i = 0; i < nResults; i++) {

			greenstring = greenstring+name+","+f+1+","+CS+","+FO+","+i+1+","+getResult("Area",i)+","+getResult("Perim.",i)+","+getResult("IntDen",i)+","+getResult("RawIntDen",i)+"\n";
			       	}
	}
	if( channel == "red" )  {
		for (i = 0; i < nResults; i++) {
			redstring = redstring+name+","+f+1+","+CS+","+FO+","+i+1+","+getResult("Area",i)+","+getResult("Perim.",i)+","+getResult("IntDen",i)+","+getResult("RawIntDen",i)+"\n";
		       	}
	}
	run("Clear Results");
	selectImage(channel+" Segmented"); close();

	if( channel == "green" )  {
		gcount = roiManager("Count");
		}
	if( channel == "red" )  {
		rcount = roiManager("Count");
		}
  
	selectImage(name+"_"+channel+"_mask.tif");
	rename(channel+" mask");
	
	if( roiManager("Count") > 0 )
		{
		roiManager("Save",resultdir+folderlist[f]+name+"_"+channel+"_ROI.zip");
		run("Clear Results");	
		selectImage(channel);
		roiManager("Combine");
		roiManager("Add");
		countss=roiManager("count");
		roiManager("select", countss-1);
		roiManager("measure");
		selectWindow("Results");
		if( channel == "green")
		{
			for(j=0;j<nResults;j++) {
			greensum = greensum+name+","+f+1+","+CS+","+FO+","+gcount+","+axonlength+","+getResult("Area",j)+","+getResult("IntDen",j)+","+getResult("RawIntDen",j)+","+"	"+","+(gcount/axonlength)*10+","+(getResult("Area",j)/gcount)+","+(getResult("RawIntDen",j)/getResult("Area",j))+"\n";
					}
	}
		if( channel == "red")
		{
			for(j=0;j<nResults;j++) {
			redsum = redsum+name+","+f+1+","+CS+","+FO+","+rcount+","+axonlength+","+getResult("Area",j)+","+getResult("IntDen",j)+","+getResult("RawIntDen",j)+","+"	"+","+(rcount/axonlength)*10+","+(getResult("Area",j)/rcount)+","+(getResult("RawIntDen",j)/getResult("Area",j))+"\n";
					}
	}
	roiManager("reset");
	}
	}

//this function opens the saved ROI files for the green and red channels of each image and overlays them
//either using the green mask as the base image and checking for overlap of the red puncta or vice versa
//because the puncta sizes differ, this can be pretty variable between G and R
//upon checking by hand, at 25% overlap, the one that most closely aligns is GR
//this is also the last step in the analysis process for a single image, so it prints out the results of the image.
function measure() {
	totalgreenrcount = 0;
	totalredgcount = 0;
	redgcount = 0;
	greenrcount = 0;
	if( gcount > 0 ) {
  		roiManager("Open", resultdir+folderlist[f]+name+"_green_ROI.zip");
	
	selectImage("red mask");
	run("Clear Results");
	roiManager("Measure");
	}
	grcount=0;
	x = 0;
	for(i=0;i<gcount;i++) {
		totalgreenrcount = totalgreenrcount + getResult("%Area",i);
		if( getResult("%Area",i) >= areapercent ) {
			grcount++;
			greenrcount = greenrcount + getResult("%Area",i);
		}
		x++;
	}
	xgreen = x;
	totalgreenrcount = totalgreenrcount/x;
	greenrcount = greenrcount/grcount;
	roiManager("reset"); 
	run("Clear Results");
	
	if( rcount > 0 ) {
  		roiManager("Open", resultdir+folderlist[f]+name+"_red_ROI.zip");
	
	selectImage("green mask");
	run("Clear Results");
	roiManager("Measure");
	}
	rgcount=0;
	x = 0;
	for(i=0;i<rcount;i++) {
		totalredgcount = totalredgcount + getResult("%Area",i);
		if( getResult("%Area",i) >= areapercent ) {
			rgcount++;
			redgcount = redgcount + getResult("%Area",i);
		}
		x++;
	}
	xred = x;
	totalredgcount = (totalredgcount/x);
	redgcount = redgcount/rgcount;
	roiManager("reset"); 
	run("Clear Results");
	

//print("Condition	Coverslip	N	GreenPuncta#	RedPuncta#	GR#	RG#	length	G_10um	R_10um	GR_10um	RG_10um 	 	gr_%AreaAvg(counted)	gr_%AreaAvg(total)	gr_totalCounted	rg_%AreaAvg(counted)	rg_%AreaAvg(total)	rg_totalCounted	\n");
	print(name+"	"+f+1+"	"+CS+"	"+FO+"	"+gcount+"	"+rcount+"	"+grcount+"	"+rgcount+"	"+axonlength+"	"+(gcount/axonlength)*10+"	"+(rcount/axonlength)*10+"	"+(grcount/axonlength)*10+"	"+(rgcount/axonlength)*10+" 	 	"+greenrcount+"	"+totalgreenrcount+"	"+xgreen+"	"+redgcount+"	"+totalredgcount+"	"+xred);
 
	close("*"); 
}
