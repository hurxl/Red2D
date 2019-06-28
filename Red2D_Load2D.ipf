#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function/S Red2D_Load2D()
	Variable refNum
	String message = "Select one or more files"
	String outputPaths
	String fileFilters = "Data Files (*.tiff,*.tif):.tiff,.tif;"
	fileFilters += "All Files:.*;"
 
	Open /D /R /MULT=1 /F=fileFilters /M=message refNum
	outputPaths = S_fileName //S_filename stores the selected files names by return "\r"
 	
	if (strlen(outputPaths) == 0)
		Print "Cancelled"
		return outputPaths		// Will be empty if user canceled
	else
		Variable numFilesSelected = ItemsInList(outputPaths, "\r")
		Variable i
		for(i=0; i<numFilesSelected; i+=1)
			
			String path = StringFromList(i, outputPaths, "\r") // Get the path of ith of selected waves.
			ImageLoad/T=tiff/Q/O path
			
			// Remove extension from the loaded wavename
			String wn0 = RemoveEnding(S_WaveNames,";") // Get loaded wavename and remove the separator.
			String wn1 = RemoveEnding(wn0,".tif") // Remove the extension
			String wn2 = RemoveEnding(wn1,".tiff") // Remove the extension
			Rename $(wn0) $(wn2)
		
		endfor
	endif
	
 	Print "Load Success"
	
End