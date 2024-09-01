#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function R2D_Load_SAXSpoint_zip()
	
	string unzippedTmpPath = R2D_unzipH5zip()
	
	R2D_Load_SAXSpoint_h5_files(unzippedTmpPath)
	
End


Function/S R2D_unzipH5zip()
	
	variable refnum
	string fileFilters = "Zipped HDF Files (*.h5z):.h5z;"
	
	Open/D/R/F=fileFilters/M="Select a zip file" refNum
	
	// if no files is selected, close this proceddure.
	if (strlen(S_fileName) == 0)
		Print "User cancelled"
	endif
	
	string archivePathStr = S_fileName
	string unzippedPathStr = SpecialDirPath("Igor Pro User Files", 0, 0, 0) + "tmp"
	
	UnzipFile/O archivePathStr, unzippedPathStr
	if(V_flag == 0)
		NewPath/O IgorUserTmp, unzippedPathStr
		string filepath = unzippedPathStr + ":" + IndexedFile(IgorUserTmp, 0, ".h5")
		print "The zip is expaneded in " +filepath
		return filepath
	else
		print "Unzipping failed."
		return ""
	endif

End

Function R2D_Load_SAXSpoint_h5_files(filePath)
	string filePath
	print filePath
	
	Variable fileID		// HDF5 file ID will be stored here
	Variable result = 0	// 0 means no error
	
	// Open the HDF5 file
	HDF5OpenFile/R fileID as filePath
	if (V_flag != 0)
		Print "HDF5OpenFile failed"
		return -1
	endif
	
	// Load the HDF5 dataset
	
	HDF5LoadData/Q/O/Z/N = imagestack_raw fileID, "/entry/data/data" // load imagefiles stack
	HDF5LoadData/Q/O/Z/N = measeurment_time fileID, "/entry/data/count_time" // load measeurment time
	HDF5LoadData/Q/O/Z/N = transmittance fileID, "/entry/data/transmittance" // load transmittance
	HDF5LoadData/Q/O/Z/N = SDD fileID, "/entry/data/sdd" // load sdd
	HDF5LoadData/Q/O/Z/N = sample_name_raw fileID, "/entry/data/sample_name" // load sample_name
	HDF5LoadData/Q/O/Z/N = temperature fileID, "/entry/data/sample_temperature" // load sample_temperature
	
	if (V_flag != 0)
		Print "HDF5LoadData failed"
		result = -1
	endif

	// Close the HDF5 file
	HDF5CloseFile fileID
	
	wave sample_name_raw
	
	variable i,j
	
	// convert num to ASCII character
	
	Make/T/O/N = (dimsize(sample_name_raw,0)) sample_name// make 1Dwave to store sample name 
	wave/T sample_name
	for(i=0; i<dimsize(sample_name_raw,0); i+=1)
		String namestring = ""
		for(j=0; j<dimsize(sample_name_raw,1); j+=1)
			if(sample_name_raw[i][j] != 0)
				namestring += num2char(sample_name_raw[i][j])
			endif
		endfor
		sample_name[i] = namestring
	endfor
	killwaves/Z sample_name_raw
	
	// stack image transform
	
	wave imagestack_raw
	MatrixOp/O imagestack = (transposeVol(imagestack_raw,3))  // Convert numofstack x 1062 x 1028 to  1028 x 1062 x numofstack
	ImageRotate/O/F  imagestack // Rotates the image by 180 degrees
	Multithread imagestack[][][] = imagestack[p][q][r] <= -1 ? NaN : imagestack[p][q][r] // negative values to NaN; pixels with NaN are auto
	

	killwaves/Z imagestack_raw
	
	return result
End

