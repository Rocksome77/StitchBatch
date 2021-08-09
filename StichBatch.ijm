// Medium throughput microscopy pacakges Colombus amd Harmony both export their images in a strange numbering system where image #1 is an image from the centre of the well
// and subsequent the numbering starts at #2 in the top-left, then snakes from left-to-right then right-to left, skipping image #1.
// This is an ImageJ script that renames all the images starting from #1 in the top-left, stitches the images in every colour channel together using the Grid Stitch package
// and then overlays each individual stitched colour channel into a single multi-channel image.
// Images are loaded using the Colmbus generalised image naming format: "00y00x-f-00t00z00c.tif"
// where y is the row, x  is the column, f is the field of view, t is the time series, z is the vertical stack position and c is the colour channel. Currently only implemented for time point 1 and z-position 1.

input = getDirectory("Input directory"); // Identify folder containing the individual source images
File.makeDirectory(input+"renamed/") // Creates a subdirectory of the input folder to put copies of the renamed files. This prevents accindentally running the script on the data multiple times and shifting the images out of alignment when renaming multiple times
File.makeDirectory(input+"renamed/stitched/") // Creates a subdirectory of the renamed folder to store the stitched images
File.makeDirectory(input+"renamed/stitched/overlayed/") // Creates a subdirectory of the stitched folder to store the images with multiple channels overlayed

rowStart = 6; 	// A = 1, B = 2, C = 3, etc... Change this number to the starting row of the wells you want to stitch (top to bottom). This script only works for a rectangular grid of wells
rowEnd = 6;  	// A = 1, B = 2, C = 3, etc... Change this number to the final row of the wells you want to stitch.
colStart = 7; // Change this number to the starting column of the wells you want to stitch (left to right). This script only works for a rectangular grid of wells.
colEnd = 7; // Change this number to the final column position of the wells you want to stitch

FOVwidth = 5; // Change this number to the number of FOVs across each well you want to stitch.
FOVheight = 7; // Change this number to the number of FOVs down each well you want to stitch.

centralWell = ((floor((FOVheight-1)/2))*FOVwidth)+ floor(FOVwidth/2) + 1 - (FOVheight%2*(1-FOVwidth%2)) ; // If the number of field of view rows is odd then image #1 should be placed after half of the rows have been completed (rounded down) and then an additional number based on the direction of the snake in that row;

for (x=colStart; x <= colEnd; x++) // Begin working across columns: left to right
	{
	for (y=rowStart; y <= rowEnd; y++) // Begin working down rows: top to bottom
		{
		if (x < 10) // Create string from column number (x co-ordinate) used for loading/saving files and adding 1 or 2 leading zeroes depending on number of digits
    			{
    			xCo = "00" + toString(x);
    			}
    			else
    			{
				xCo = "0" + toString(x);
    			}
			if (y < 10) // Create string from row number (y co-ordinate) used for loading/saving files and adding 1 or 2 leading zeroes depending on number of digits
    			{
    			yCo = "00" + toString(y);
    			}
    			else
    			{
				yCo = "0" + toString(y);
    			}
			for (c=1; c <= 4; c++) // Begin working through channels: lowest to highest
				{
				cCo = "00" + toString(c); // Create string from channel number (c co-ordinate) used for loading/saving files
				renameimages(xCo, yCo, cCo, centralWell);
				genericFilename = yCo + xCo +"-{i}-001001"+cCo+".tif";   		
				wellCoord = yCo + xCo + cCo;
				print("Stitching "+input+"renamed/"+genericFilename+" into " + input +"renamed/stitched/"+wellCoord);
			  	stitch(input+"renamed/", input +"renamed/stitched/", genericFilename, wellCoord);
				}
			filename = yCo + xCo; // Generates partial new filename for overlayed images 
			print("Overlaying "+ input +"renamed/stitched/"+filename+" into " + input +"renamed/stitched/overlayed/"+filename); // Display overlaying filenames for debugging
    		overlay(input +"renamed/stitched/", input +"renamed/stitched/overlayed", filename); // overlay calling overlay function below
		}
	}
	
function renameimages(xCo, yCo, cCo, centralWell) {
	for (f=1; f <=centralWell; f++)    // Begin working through each FOV: lowest to the central well
		{
		f2 = f-1; // Shift all images down one step
		oldName = yCo + xCo +"-"+f+"-001001"+cCo+".tif"; //old filename
		newName = yCo + xCo +"-"+f2+"-001001"+cCo+".tif"; // new filename
		print("Renaming "+input +oldName+" as "+input+"renamed/"+newName); // Display new and old filenames for debugging
		File.rename(input + oldName, input +"renamed/"+newName); // shift all image before the central well down 1 step and into the "renamed" folder
		}
	oldName = yCo + xCo +"-0-001001"+cCo+".tif"; //after all images are shifted down one, image #0 (originally image #1) image is saved into the slot created in the centre of the well when everying shofted down one
	newName = yCo + xCo +"-"+centralWell+"-001001"+cCo+".tif"; 	
	print("Renaming "+input+"renamed/" +oldName+" as "+input+"renamed/"+newName);
	File.rename(input+"renamed/" + oldName, input +"renamed/"+newName);
	for (f=centralWell+1; f <=FOVwidth * FOVheight; f++)
		{
   		oldName = yCo + xCo +"-"+f+"-001001"+ cCo+".tif"; // For the remained for the wells keep filenames the same but move to the renamed folder 
    	print("Renaming "+input +oldName+" as "+input+"renamed/"+oldName);
		File.rename(input + oldName, input+"renamed/"+oldName);		
		}
	}

function stitch(input, stitched, genericFilename, wellCoord) {
    run("Grid/Collection stitching", "type=[Grid: snake by rows] order=[Right & Down                ] grid_size_x="+FOVwidth+" grid_size_y="+FOVheight+" tile_overlap=5 first_file_index_i=1 directory=" + input + " file_names=" + genericFilename + " output_textfile_name=" + wellCoord + ".txt fusion_method=[Linear Blending] regression_threshold=0.30 max avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 subpixel_accuracy computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
    run("8-bit"); // Calls image stitching function and supplies settings for stitching: currently optimsied for my experiment. Will need to be adapted for your settings.
    saveAs("Tiff", stitched + wellCoord); // Save stitched image using abbreviated filename into "stitched" folder.
    close();
}

function overlay(stitched, overlayed, filename) {
		open(stitched+filename+ "001.tif"); // Open each colour channel image seperately
		open(stitched+filename+ "002.tif"); 
		open(stitched+filename+ "003.tif");
		open(stitched+filename+ "004.tif");
		selectWindow(filename+ "001.tif"); // Focus on each channel window and set the lookup table for colours
		run("Red");  		
		selectWindow(filename+ "002.tif");
		run("Yellow");  			
		selectWindow(filename+ "003.tif");
		run("Green");  			
		selectWindow(filename+ "004.tif");
		run("Blue"); 			
		run("Merge Channels...", "c1="+filename+"001.tif c2="+filename+"002.tif c3="+filename+"003.tif c4="+filename+"004.tif create"); // Merge channels by filename
		selectWindow("Composite"); // Focus on merged window and save composite image as tif in "overlayed" folder
		saveAs("Tiff", overlayed+"/"+filename+".tif");
		close();
}