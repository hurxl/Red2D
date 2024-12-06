#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

Function/S R2D_Load_SAXSpoint_zip()

	// Windows or Mac
	string os = IgorInfo(2)

	// Igor User Folder
	PathInfo IgorUserFiles
	string PCpath_IgorUserFiles
	
	// Create tmp folder inside Igor Pro User Files
	string TempFolderPath
	string cmd
	String path
	if(stringmatch(os,"Macintosh"))	// Mac
		PCpath_IgorUserFiles = ParseFilePath(5, S_path,"/",0,0) // convert symbolic path to MacOS UNIX path.
		TempFolderPath = PCpath_IgorUserFiles + "tmp"
		sprintf cmd, "mkdir -p '%s'", TempFolderPath
		R2D_ExecuteUnixShellCommand(cmd, 0, 0)
	elseif(stringmatch(os, "Windows"))	// Windows
		PCpath_IgorUserFiles = ParseFilePath(5, TempFolderPath,"\\",0,0)	// convert symbolic path to Windows path.
		TempFolderPath = PCpath_IgorUserFiles + "tmp"
		sprintf cmd, "mkdir '%s'", TempFolderPath
		R2D_ExecuteWindowsShellCommand(cmd, 0, 0)
	endif
	
	PathInfo IgorUserFiles
	TempFolderPath = S_path + "tmp"
	
	NewPath/O IgorUserTmp, TempFolderPath

	String h5list = IndexedFile(IgorUserTmp, -1, ".h5") // get h5 file list in tmp folder
	variable i
	for(i=0; i<itemsInList(h5list); i++) // delete all h5 file in tmp folder
		String h5file = StringFromList(i, h5list)
		deleteFile/Z/P=IgorUserTmp h5file	
	endfor

	string unzippedTmpPath = R2D_unzipH5zip()
	if (numtype(strlen(unzippedTmpPath)) == 0 )
//		R2D_Load_SAXSpoint_h5_files(unzippedTmpPath)			
	endif
	
	h5file = IndexedFile(IgorUserTmp, 0, ".h5")
	deleteFile/Z/P=IgorUserTmp h5file	
	
End

Function/S R2D_unzipH5zip()
	
	variable refnum
	string fileFilters = "Zipped HDF Files (*.h5z):.h5z;"
	
	Open/D/R/F=fileFilters/M="Select a zip file" refNum
	
	// if no files is selected, close this proceddure.
	if (strlen(S_fileName) == 0)
		Print "User cancelled"
	else
	
	string archivePathStr = S_fileName
	string TempFolderPath = SpecialDirPath("Igor Pro User Files", 0, 0, 0) + "tmp"
	
	UnzipFile/Z/O archivePathStr, TempFolderPath
	
		if(V_flag == 0) //  the operation succeeds
			NewPath/O IgorUserTmp, TempFolderPath
			string filepath = TempFolderPath + ":" + IndexedFile(IgorUserTmp, 0, ".h5")
			print "The zip is expaneded in " +filepath
			return filepath
		else
		
			print "Unzipping failed."
			return ""
		endif
	endif
End

Function R2D_Load_SAXSpoint_h5_files(filePath)
	string filePath
	print filePath
	
	Variable fileID		// HDF5 file ID will be stored here
	Variable result = 0	// 0 means no error
	
	// Open the HDF5 file
	HDF5OpenFile /R fileID as filePath
	if (V_flag != 0)
		Print "HDF5OpenFile failed"
		return -1
	endif
	
	// Load the HDF5 dataset
	
	HDF5LoadData/Q/O/Z/N = imagestack_raw fileID, "/entry/data/data" // load imagefiles stack
	HDF5LoadData/Q/O/Z/N = measeurment_time fileID, "/entry/data/count_time" // load measeurment time
	HDF5LoadData/Q/O/Z/N = averaged_frames fileID, "/entry/data/averaged_frames" // load averaged frames
	HDF5LoadData/Q/O/Z/N = transmittance fileID, "/entry/data/transmittance" // load transmittance
	HDF5LoadData/Q/O/Z/N = SDD fileID, "/entry/data/sdd" // load sdd
	HDF5LoadData/Q/O/Z/N = sample_name_raw fileID, "/entry/data/sample_name" // load sample_name
	HDF5LoadData/Q/O/Z/N = sample_temperature fileID, "/entry/data/sample_temperature" // load sample_temperature
	HDF5LoadData/Q/O/Z/N = sample_thickness fileID, "/entry/data/sample_thickness" // load sample_thickness
	HDF5LoadData/Q/O/Z/N = sample_column fileID, "/entry/data/sample_column" // load sample_column
	HDF5LoadData/Q/O/Z/N = sample_row fileID, "/entry/data/sample_row" // load sample_row	
	HDF5LoadData/Q/O/Z/N = ambient_status_raw fileID, "/entry/data/ambient_status" // load ambient_status Air or VAcuum	
	HDF5LoadData/Q/O/Z/N = wavelength fileID, "/entry/data/wavelength" // load wavelength
	HDF5LoadData/Q/O/Z/N = flux_entering_sample fileID, "/entry/data/flux_entering_sample" // load flux_entering_sample
	HDF5LoadData/Q/O/Z/N = flux_exiting_sample fileID, "/entry/data/flux_exiting_sample" // load flux_exiting_sample
	
	HDF5LoadData/Q/O/Z/N = description fileID, "/entry/instrument/detector/description" // load detector namme
	HDF5LoadData/Q/O/Z/N = detector_number fileID, "/entry/instrument/detector/detector_number" // load detector_number
	HDF5LoadData/Q/O/Z/N = x_pixel_size fileID, "/entry/instrument/detector/x_pixel_size" // load x_pixel_size
	HDF5LoadData/Q/O/Z/N = y_pixel_size fileID, "/entry/instrument/detector/y_pixel_size" // load y_pixel_size
	
	
	if (V_flag != 0)
		Print "HDF5LoadData failed"
		result = -1
	endif

	// Close the HDF5 file
	HDF5CloseFile fileID
	
	wave sample_name_raw
	wave sample_column
	wave sample_row
	wave sample_temperature
	wave ambient_status_raw
	wave imagestack_raw

	
	variable i,j
	
	// convert num to ASCII character
	
	Make/T/O/N = (dimsize(sample_name_raw,0)) sample_name// make 1Dwave to store sample name 
	Make/T/O/N = (dimsize(sample_column,0)) sample_position// make 1Dwave to store sample position
	Make/T/O/N = (dimsize(ambient_status_raw,0)) ambient_status// make 1Dwave to store ambient status

	wave/T sample_name
	wave/T sample_position
	wave/T ambient_status

	for(i=0; i<dimsize(sample_name_raw,0); i+=1)
		String namestring = ""
		String columnstring = ""
		String ambientstring = ""
		for(j=0; j<dimsize(sample_name_raw,1); j+=1)
			if(sample_name_raw[i][j] != 0)
				namestring += num2char(sample_name_raw[i][j])
			endif
			
			if (j < 128) // Bsecause size of sample_column and sample_row wave diffrerents with  sample_name_raw
				if(sample_column[i][j] != 0)
					columnstring += num2char(sample_column[i][j]) //Sample column
				endif			
						
				if(sample_row[i][j] != 0)
					columnstring += num2char(sample_row[i][j]) //Sample row
				endif
				
				if(ambient_status_raw[i][j] != 0)
					ambientstring += num2char(ambient_status_raw[i][j])  //Ambient status
				endif
			endif						
		endfor
		
		sample_name[i] = namestring
		sample_position[i] = columnstring 
		ambient_status[i] = ambientstring 
		
	endfor
	killwaves/Z sample_name_raw, sample_column, sample_row, ambient_status_raw
	
	//stack image transform
	
	MatrixOp/O imagestack = (transposeVol(imagestack_raw,3))  // Convert numofstack x 1062 x 1028 to  1028 x 1062 x numofstack
	ImageRotate/O/V  imagestack // Flip the image vertically.
	Multithread imagestack[][][] = imagestack[p][q][r] <= -1 ? NaN : imagestack[p][q][r] // negative values to NaN; pixels with NaN are auto	

	killwaves/Z imagestack_raw
	
	//Conversion of sample temperature units　K -> C

	sample_temperature = sample_temperature - 273.15
	
	Red2D_SpliteImageStack()	
	
	print "Image loading completed..."
	
	return result
End

function Red2D_SpliteImageStack()		
	wave imagestack	
	wave transmittance
	wave SDD
	wave sample_temperature
	wave measeurment_time
	wave averaged_frames
	wave/T sample_position
	wave/T sample_name
	wave/T ambient_status
	wave wavelength
	wave flux_entering_sample
	wave flux_exiting_sample
	wave sample_thickness
	// 1 point wave
	wave/T description
	wave/T detector_number
	wave x_pixel_size
	wave y_pixel_size
	
	variable lay = DimSize(imagestack, 2)
	lay = max(lay,1)	//  Check if there is only one image. 

	variable i
	
	string namelist = ""
	string imagename 
	
	for(i=0; i< lay	; i+=1) // Making image wavelist 
		imagename = ""
		imagename += sample_name[i]
		imagename += "_"+"SDD_"+num2str(round(SDD[i]*1000))+"mm"
		imagename += "_"+sample_position[i]
		imagename += "_"+num2str(round(sample_temperature[i]))+"C"
		imagename = R2D_CleanupName(imagename)
		
		imagename = CreateDataObjectName($("SDD_"+num2str(round(SDD[i]*1000))+"mm"), imagename, 1, 0, 1) // Make unique name
		
		print imagename
		
		namelist += imagename + ";"

	endfor
	
	if (lay >> 1) //
		SplitWave/O/SDIM=2/NAME=namelist imagestack //Split 3dwave to 2dwave	
	else
		duplicate/O imagestack, $(StringFromList(0, namelist))
	endif


	
	string wnote = ""
		
	for(i=0; i< lay	; i+=1) // Writing note
		wave target = $(StringFromList(i, namelist))
		
		wnote += "Detector : "+ description[0]+"	 S/N "+detector_number[0]+"\r"
		wnote += "Pixel size : "+ num2str(x_pixel_size[0]*1e6)+" [µm]"+" × "+ num2str(y_pixel_size[0]*1e6)+" [µm]"+"\r"
		wnote += "Sample name : "+sample_name[i]+"\r"
		wnote += "Ambient status : "+ ambient_status[i] + "\r"
		wnote += "Wavelength : "+num2str(wavelength[i]*1e10)+" [Å]"+"\r"
		wnote += "SDD : "+num2str(SDD[i])+" [m]"+"\r"
		wnote += "Sample position : "+sample_position[i]+"\r"
		wnote += "Measeurment time : "+num2str(measeurment_time[i])+" [sec]"+"\r"
		wnote += "Averaged frames : "+num2str(averaged_frames[i])+"\r"
		wnote += "Sample temperature : "+num2str(sample_temperature[i])+" [C]"+"\r"
		wnote += "sample_thickness : "+num2str(sample_thickness[i]/100)+" [cm]"+"\r"	
		wnote += "Transmittance : "+num2str(transmittance[i])+"\r"
		wnote += "flux_entering_sample : "+num2str(flux_entering_sample[i])+" [cts]"+"\r"
		wnote += "flux_exiting_sample : "+num2str(flux_exiting_sample[i])+" [cts]"+"\r"
		
		if (strlen(note(target)) == 0)
			Note target, wnote
		endif
		
		wnote = ""
	endfor
	
	Wave SDDtype
	
	if (numpnts(SDD) >> 1)
		FindDuplicates/FREE/RN = SDDtype SDD // Find num of SDD 
	else 
		Make/O/N = 1 SDDtype
		SDDtype = SDD
		
	endif 		
 	SDDtype = round(SDDtype*1000)

	
	string strSDD
	variable j
	string list
	
	for(i=0; i< DimSize(SDDtype, 0)	; i+=1) //Separate folders for each SDD
		strSDD = "SDD_"+num2str(SDDtype[i])+"mm" // making
		NewDataFolder/O $(strSDD) 
		DFREF dfr = $(":"+strSDD)
		list = wavelist("*"+strSDD+"*",";","DIMS:2")
			for(j=0; j< ItemsInList(list);j+=1)
				
				string wName = StringFromList(j, list)
				duplicate/O  $(wName), dfr:$(StringFromList(j, list))
				killwaves/Z  $(wName)
			endfor

	endfor
	
	String allwlist = wavelist("*",";","DIMS:1")
	for(i=0; i< ItemsInList(allwlist);i+=1)
		killwaves/Z $(StringFromList(i, allwlist))
	endfor
	
	killwaves/Z imagestack

end


//Function Red2D_writeValToDatasheet(ImageName, colStr, val, format) // this is same function as DLS package
//	string ImageName
//	string colStr
//	variable val
//	string format
//	
//	// check if summary wave exists, if specified column exists, and if the ImageName exists.
//	wave/Z/T Datasheet = $(GetDatasheetPath())
//	if(!WaveExists(Datasheet))
//		Print "Datasheet does not exist in Red2Dpackage. Stop writing to Datasheet."
//		return -1
//	endif
//	variable colindex = FindDimLabel(Datasheet, 1, colStr)
//	if(colindex < 0)	// not found
//		Print colStr +" does not exist in the Datasheet. Stop writing to Datasheet."
//		return -1
//	endif
//	variable nameindex = FindDimLabel(Datasheet, 1, "ImageName")
//	FindValue/TEXT=(ImageName)/RMD=[][nameindex] Datasheet
////	print imagename
//	if(V_row < 0)
//		Print "The specified ImageName does not exist in the Datasheet. Stop writing to Datasheet."
//		return -1
//	endif
//	
//	// write the val to summary
//	if(numtype(val) == 2)	// if val = NaN, make it to an empty string.
//		Datasheet[V_row][colindex] = ""
//	else
//		Datasheet[V_row][colindex] = num2str(val, format)
//	endif
//	
//	return 0
//	
//End
//
//function Red2D_writeTimeAndTrnasToDatasheet()
//	String Datasheet_Path = GetDatasheetPath()  // get path of the datasheet. if in a wrong datafolder, return an error and abort.
//	wave/T/Z datasheet = $Datasheet_Path
//	String imagefolder = GetWavesDataFolder(datasheet,1)+":" // get the full path of the datafolder for datasheet
//	
//	String imagename
//	String imagepath
//	String target
//	String image_note
//	String buffer
//	variable numInDatasheet = Dimsize(Datasheet, 0)
//	variable i, j, v
//	
//	for(i=0; i<numInDatasheet; i+=1)	 // get note from image wave
//		imagename = Datasheet[i][%ImageName]  // get imagename
//		print ImageName
//		imagepath = imagefolder+imagename  // set image full path. the user may be in the image folder and 1d folder.
//		image_note = note($imagepath)  // get note of the image
//				
//		for(j=0; j<ItemsInList(image_note, "\r"); j+=1)
//			buffer = StringFromList(j, image_note, "\r")
//			
//			If (stringmatch(buffer, "Measeurment time *")) // write Measeurment time
//				sscanf buffer , "Measeurment time : %f", v
//				Red2D_writeValToDatasheet(imagename, "Time_s", v, "%g")
//			endif
//			
//			If (stringmatch(buffer, "Transmittance *")) // write trans 
//				sscanf buffer , "Transmittance : %f", v
//				Red2D_writeValToDatasheet(imagename, "Trans", v, "%f")
//			endif
//			
//		endfor
//		
//	endfor
//end


Function R2D_FillDataseetSAXSpoint()

	R2D_FillDataseet_worker("Sample Name", " : ", "\r", "SampleName")
	R2D_FillDataseet_worker("Measeurment time", " : ", "\r", "Time_s")
	R2D_FillDataseet_worker("Transmittance", " : ", "\r", "Trans")
	R2D_FillDataseet_worker("sample_thickness", " : ", "\r", "Thick_cm")

End

Function R2D_FillDataseet_worker(Key, KeySeparator, ListSeparator, DatasheetColName)
	String Key
	String KeySeparator
	String ListSeparator
	String DatasheetColName
	
	String Datasheet_Path = GetDatasheetPath()  // get path of the datasheet. if in a wrong datafolder, return an error and abort.
	wave/T/Z datasheet = $Datasheet_Path
	String imagefolder = GetWavesDataFolder(datasheet,1)+":" // get the full path of the datafolder for datasheet

	String imagename
	String imagepath
	String target
	String image_note
	variable numInDatasheet = Dimsize(Datasheet, 0)
	variable i
	
	For(i=0; i<numInDatasheet; i++)
		imagename = Datasheet[i][%ImageName]  // get imagename
		imagepath = imagefolder+imagename  // set image full path. the user may be in the image folder and 1d folder.
		image_note = note($imagepath)  // get note of the image
		target = StringByKey(key, image_note, KeySeparator, ListSeparator)  // get sample name in the note
		if(strlen(target) == 0 || numtype(strlen(target)) == 2)
			// do nothing
		else
			Datasheet[i][%$DatasheetColName] = target
		endif
	Endfor

End


// Execute Shell Command
Function/S R2D_ExecuteUnixShellCommand(uCommand, printCommandInHistory, printResultInHistory) //Execute shell command, e.g. Contin
    String uCommand                         // Unix command to execute
    Variable printCommandInHistory
    Variable printResultInHistory

	if (printCommandInHistory)
	printf "Unix command: %s\r", uCommand // %s is where the uCommand will be inserted
	endif

	String cmd
	sprintf cmd, "do shell script \"%s\"", uCommand // %s is where the uCommand will be inserted
	ExecuteScriptText/UNQ/Z cmd      // /UNQ removes quotes surrounding reply
//	Print cmd
           
    if (printResultInHistory)
		Print S_value
    endif
    
	return S_value
End

Function/S R2D_ExecuteWindowsShellCommand(uCommand, printCommandInHistory, printResultInHistory) //Execute shell command, e.g. Contin
    String uCommand                         // Unix command to execute
    Variable printCommandInHistory
    Variable printResultInHistory

	if (printCommandInHistory)
	printf "Windows command: %s\r", uCommand // %s is where the uCommand will be inserted
	endif

	String cmd
	sprintf cmd, "cmd.exe /C %s", uCommand // %s is where the uCommand will be inserted
	ExecuteScriptText/B/Z cmd      // /UNQ removes quotes surrounding reply
//	Print cmd
           
    if (printResultInHistory)
		Print S_value
    endif
    
	return S_value
End
