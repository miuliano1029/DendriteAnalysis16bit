//Redone - MARIA IULIANO 2021 with help from A Paquette based on Bea C. 2018
//NOTE: length is an estimation. for best results, please generate your own axon/dendrite length for post-processing
//original macro by Lai Ding at Harvard
// ImageJ initialize
run("Colors...", "foreground=white background=black selection=magenta");
run("Options...", "iterations=1 count=1 black edm=Overwrite");
run("Set Measurements...", "area perimeter area_fraction limit redirect=None decimal=3");
//set raw result folder. rawdir contains multiple subfolders, each subfolder contains multiple raw images
// result folder should be empty.
rawdir=getDirectory("Choose Starting Images Folder");
resultdir=getDirectory("Choose Result Folder");
axondir=getDirectory("Choose Mask Output Folder");
//variable setup
var greenThreshold, redThreshold, areapercent, scale, minsize, maxsize, name, gcount, rcount, grcount, rgcount, axonlength, axonflag
var greenstring, redstring, resultlist, FolderCreate, foldername, redgcount, greenrcount, totalredgcount, totalgreenrcount;
// input parameter
run("Set Measurements...", "area perimeter integrated area_fraction limit redirect=None decimal=5");
parameterinput();
print("Raw_Folder:	"+rawdir);
print("Result_Folder:	"+resultdir);
print("GreenThreshold	RedThreshold	AreaPercent(%)	PixelScale(um/pixel)	Min_Puncta_Size	Max_Puncta_Size");
print(greenThreshold+"	"+redThreshold+"	"+areapercent+"	"+scale+"	"+minsize+"	"+maxsize);
print(" 	GreenPuncta#	RedPuncta#	GR#	RG#	DendriteLength(um)	Density_G(#/um)	Density_R(#/um)	Density_GR(#/um)	Density_RG(#/um)		gr_%AreaAvg(counted)	gr_%AreaAvg(total)	gr_totalCounted	rg_%AreaAvg(counted)	rg_%AreaAvg(total)	rg_totalCounted");
folderlist=getFileList(rawdir);
//the below code was added as apart of a replacement for a javascript that automatically created and selected a subfolder 
//for the result data. It broke and there is now an imagej language only fix.
//Dialog.create("Conditions");
//  Dialog.addMessage("How many conditions do you have?");
//  conditions = newArray(1,2,3,4,5,6,7,8);
//  Dialog.setInsets(2,40,2);
//  Dialog.addChoice("",conditions);
//Dialog.show();
//FolderCreate = Dialog.getChoice();
//
for(f=0;f<folderlist.length;f++) 
    {
    greenstring="Filename\t  #\t   Area\t	Perim\t   %Area\n";
    redstring="Filename\t  #\t   Area\t	Perim\t   %Area\n";
    print(File.isDirectory(folderlist[f]));
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
        // mask axon, and get length;
        axon();
        //measure
        measure();
        temptitle = File.getName(rawdir+folderlist[f]);
        }
    File.saveString(greenstring, resultdir+folderlist[f]+temptitle+"_GreenArea.csv");
    File.saveString(redstring, resultdir+folderlist[f]+temptitle+"_RedArea.csv");  
    }
selectWindow("Log");
saveAs("Text", resultdir+"Summary.csv");
selectWindow("Log"); run("Close");
selectWindow("Results"); run("Close");
selectWindow("ROI Manager"); run("Close");
//the following functions are listed in order of use in the macro
//thresholding parameters are generally the only ones that need changing, but all can be modified
function parameterinput()
    {
    Dialog.create("Parameter");
        Dialog.addNumber("Green Threshold:", 181);
        Dialog.addNumber("Red Threshold:", 196);
        Dialog.addNumber("Area Percent (%):", 25);
        Dialog.addNumber("Pixel Scale (um/pixel):", 0.06025);
        Dialog.addNumber("Min Puncta Size (pixel):", 4);
        Dialog.addNumber("Max Puncta Size (pixel):", 200);
    Dialog.show();
    greenThreshold = Dialog.getNumber();
    redThreshold = Dialog.getNumber();
    areapercent = Dialog.getNumber();  
    scale = Dialog.getNumber();  
    minsize = Dialog.getNumber();  
    maxsize = Dialog.getNumber();
    }
    
//this function opens the appropriate image from the appropriate folder in the raw data folder
//gets the name, standardizes the properties of the image, splits the channels and discards the blue channel as "axon" to be saved elsewhere
function initialize()
 {
    open(rawdir+foldername+File.separator+rawlist[d]);
    name=getInfo("image.filename");
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
function mask(channel)
	{
	selectImage(channel);
	if( channel == "green") {
		setThreshold(greenThreshold, 255);
		}
	if( channel == "red") {
		setThreshold(redThreshold, 255);
		}
	run("Find Maxima...", "noise=10 output=[Segmented Particles] above");
	run("Analyze Particles...", "size="+minsize+"-"+maxsize+" pixel show=Masks add");
	selectWindow("Mask of "+channel+" Segmented");  
	run("Grays");
	saveAs("Tiff", resultdir+folderlist[f]+name+"_"+channel+"_mask.tif");
	run("Clear Results");
	roiManager("Measure");
	selectWindow("Results");
  
	if( channel == "green")
		{
		for(j=0;j<nResults;j++) {
			greenstring = greenstring+filelist[d]+"	"+j+1+"	"+getResult("Area",j)+"	"+getResult("Perim.",j)+" 	"+getResult("%Area",j)+"\n";
			}
		}
	if( channel == "red")
		{
		for(j=0;j<nResults;j++) {
			redstring = redstring+filelist[d]+"	"+j+1+"	"+getResult("Area",j)+"	"+getResult("Perim.",j)+" 	"+getResult("%Area",j)+"\n";
			}
		}
  
	run("Clear Results");
	rename(channel+" mask");
	selectImage(channel); close();
	selectImage(channel+" Segmented"); close();

	if( channel == "green" )  {
		gcount = roiManager("Count");
		}
	if( channel == "red" )  {
		rcount = roiManager("Count");
		}
  
	if( roiManager("Count") > 0 )
		{
		roiManager("Save",resultdir+folderlist[f]+name+"_"+channel+"_ROI.zip");
		}
	roiManager("reset");
	}

//this function increases the contrast for the blue channel (marking dendrites even though it says axons)
//and measures the length of the segment (even though this is usually also done manually as a precaution)
function axon()
	{
	selectImage("axon");
	run("Subtract Background...", "rolling=10");
	run("Gaussian Blur...", "sigma=3");
	setAutoThreshold("Triangle dark");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Skeletonize");
	run("Analyze Particles...", "size=25-infinity pixel show=Nothing add");
  
	axonlength=0;
	if( roiManager("Count") > 0 )
		{
		roiManager("Save", resultdir+folderlist[f]+name+"_axon.zip");
		run("Clear Results");
		roiManager("Measure");

		for(i=0; i< roiManager("Count"); i++)
		axonlength= axonlength + getResult("Perim.",0) ;
		axonlength = axonlength/2;

		open(rawdir+foldername+File.separator+rawlist[d]);
		roiManager("Show All");
		run("Flatten");
    	saveAs("Jpeg", axondir+foldername+"_"+name+"_show.jpg");
		close(); close();
		}
	roiManager("reset"); 
	run("Clear Results");
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
	}
	selectImage("red mask");
	run("Clear Results");
	roiManager("Measure");
	grcount=0;
	x = 0;
	for(i=0;i<roiManager("Count");i++) {
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
	}
	selectImage("green mask");
	run("Clear Results");
	roiManager("Measure");
	rgcount=0;
	x = 0;
	for(i=0;i<roiManager("Count");i++) {
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
	
	//print(" 	GreenPuncta#	RedPuncta#	GR#	RG#	AxonLength(um)	Density_G(um/#)	Density_R(um/#) Density_RG(um/#) Density_GR(um/#)");
	print(name+"	"+gcount+"	"+rcount+"	"+grcount+"	"+rgcount+"	"+axonlength+"	"+(gcount/axonlength)+"	"+(rcount/axonlength)+"	"+(rgcount/axonlength)+"	"+(grcount/axonlength)+"		"+greenrcount+"	"+totalgreenrcount+"	"+xgreen+"	"+redgcount+"	"+totalredgcount+"	"+xred);
 
	run("Close All"); 
}