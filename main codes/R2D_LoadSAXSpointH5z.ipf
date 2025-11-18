#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

// *** MISC

Function/S R2D_createtmpfolder()

	// Windows or Mac
	string os = IgorInfo(2)

	// Igor User Folder, and tmp folder
	PathInfo IgorUserFiles
	string IgorUserTmp_pathstr = S_path + "tmp"	// path string of Igor User Tmp folder	(igor does not have default tmp folder)
	
	// Check if tmp folder already exists. if not, create one.
	GetFileFolderInfo/Q/Z IgorUserTmp_pathstr
	string IgorUserTmp_pcpath
	string cmd
	If(V_flag == 0)	// tmp folder exists
		// do nothing
	else	// tmp folder does not exist
		PathInfo IgorUserFiles	// get path string of user folder again, result saved in S_path
		// note: ParseFilePath shows error for non-existing path
		if(stringmatch(os,"Macintosh"))	// Mac
			IgorUserTmp_pcpath = ParseFilePath(5, S_path,"/",0,0) + "tmp"	// convert symbolic path to MacOS UNIX path.
			sprintf cmd, "mkdir -p '%s'", IgorUserTmp_pcpath
			R2D_ExecuteUnixShellCommand(cmd, 0, 0)
		elseif(stringmatch(os, "Windows"))	// Windows
			IgorUserTmp_pcpath = ParseFilePath(5, S_path,"\\",0,0) + "tmp"	// convert symbolic path to Windows path.
			sprintf cmd, "mkdir '%s'", IgorUserTmp_pcpath
			R2D_ExecuteWindowsShellCommand(cmd, 0, 0)
		endif
	endif
	
	return IgorUserTmp_pathstr

End

Function R2D_cleanuptmpfolder(extension)
	string extension

	// cleanup tmp folder
	String filelist = IndexedFile(IgorUserTmp, -1, extension) // get file list in tmp folder
	String file
	variable i
	for(i=0; i<itemsInList(filelist); i++)	// delete all files
		file = StringFromList(i, filelist)
		deleteFile/Z/P=IgorUserTmp file	
	endfor

End


// *** MAIN

Function/S R2D_Load_SAXSpoint_h5z()

	// create a tmp folder if not exist
	string IgorUserTmp_pathstr = R2D_createtmpfolder()
	NewPath/Q/O IgorUserTmp, IgorUserTmp_pathstr	// create a symbloci path for the tmp folder

	R2D_cleanuptmpfolder(".h5")
	
	// ask user to select a h5z file
	variable refnum
	string fileFilters = "Zipped HDF Files (*.h5z):.h5z;"
	Open/D/R/F=fileFilters/M="Select a zip file" refNum
	if (strlen(S_fileName) == 0)	// if no files is selected, close this proceddure.
		Print "User cancelled"
		return ""
	else
		string h5zPath = S_fileName
	endif
	
	// unzip h5z
	string first_h5path = R2D_unzipH5zip(h5zPath, IgorUserTmp_pathstr)
	if (strlen(first_h5path) > 0 )
		R2D_Load_SAXSpoint_hdf(first_h5path)
	endif

	R2D_cleanuptmpfolder(".h5")
	
End


Function/S R2D_unzipH5zip(h5zPath, IgorUserTmp_pathstr)
	string h5zPath
	string IgorUserTmp_pathstr

	// unzip the h5z
	UnzipFile/Z/O h5zPath, IgorUserTmp_pathstr
	if(V_flag == 0) //  the operation succeeds
		string filepath = IgorUserTmp_pathstr + ":" + IndexedFile(IgorUserTmp, 0, ".h5")
		print "The h5z is extracted in " + filepath
		return filepath
	else
		print "Unzipping failed."
		return ""
	endif
End

Function R2D_Load_SAXSpoint_hdf(filePath)
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
	HDF5LoadData/Q/O/Z/N = sample_thickness fileID, "/entry/data/sample_thickness" // load Sample thickness
	HDF5LoadData/Q/O/Z/N = sample_column fileID, "/entry/data/sample_column" // load sample_column
	HDF5LoadData/Q/O/Z/N = sample_row fileID, "/entry/data/sample_row" // load sample_row	
	HDF5LoadData/Q/O/Z/N = ambient_status_raw fileID, "/entry/data/ambient_status" // load ambient_status Air or VAcuum	
	HDF5LoadData/Q/O/Z/N = wavelength fileID, "/entry/data/wavelength" // load wavelength
	HDF5LoadData/Q/O/Z/N = flux_entering_sample fileID, "/entry/data/flux_entering_sample" // load flux_entering_sample
	HDF5LoadData/Q/O/Z/N = flux_exiting_sample fileID, "/entry/data/flux_exiting_sample" // load flux_exiting_sample
	HDF5LoadData/A="file_time"/TYPE=1/Q/O/Z/N = AcquisitionStartTime fileID, "/" // load the start time for the first image capture
	HDF5LoadData/Q/O/Z/N = ElapsedTime fileID, "/entry/data/time" // load the elapsed time since the AcuisitionStartTime, this is end time of the selected image.
	
	HDF5LoadData/Q/O/Z/N = description fileID, "/entry/instrument/detector/description" // load detector namme
	HDF5LoadData/Q/O/Z/N = detector_number fileID, "/entry/instrument/detector/detector_number" // load detector_number
	HDF5LoadData/Q/O/Z/N = x_pixel_size fileID, "/entry/instrument/detector/x_pixel_size" // load x_pixel_size
	HDF5LoadData/Q/O/Z/N = y_pixel_size fileID, "/entry/instrument/detector/y_pixel_size" // load y_pixel_size
	HDF5LoadData/Q/O/Z/N = detector_x_position fileID, "/entry/instrument/detector/x_translation" // load detector x_position
	HDF5LoadData/Q/O/Z/N = detector_y_position fileID, "/entry/instrument/detector/height" // load detector y_position
	
	
//	if (V_flag != 0)
//		Print "HDF5LoadData failed"
//		result = -1
//	endif

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
	
	Redimension/S imagestack_raw
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
	wave/Z averaged_frames
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
	wave/T AcquisitionStartTime
	wave ElapsedTime
	wave detector_x_position
	wave detector_y_position
	
	variable lay = DimSize(imagestack, 2)
	lay = max(lay,1)	//  Check if there is only one image. 

	variable i
	variable image_index = 0
	
	string namelist = ""
	string imagename
	
	for(i=0; i< lay	; i+=1) // Making image wavelist 
		imagename = ""
		imagename += sample_name[i]
		imagename += "_"+"SDD_"+num2str(round(SDD[i]*1000))+"mm"
		imagename += "_"+sample_position[i]
		imagename += "_"+num2str(round(sample_temperature[i]))+"C"
		
		imagename = R2D_CleanupName(imagename)	
//		imagename = CreateDataObjectName($("SDD_"+num2str(round(SDD[i]*1000))+"mm"), imagename, 1, 0, 1) // Make unique name
		
		namelist += imagename + ";"

	endfor
	

	// add sequential number if imagenames has duplications
	string seq_namelist = R2D_AddSequentialNumbers(namelist, 1)		// 1 means remove _0 index if that string is unique
	
	
	if (lay >> 1) //
		SplitWave/O/SDIM=2/NAME=seq_namelist imagestack //Split 3dwave to 2dwave	
	else
		duplicate/O imagestack, $(StringFromList(0, seq_namelist))
	endif


	
	string wnote = ""
	variable startTime, endTime
	string startTime_str, endTime_str
	for(i=0; i< lay	; i+=1) // Writing note
		
		wave target = $(StringFromList(i, seq_namelist))
		
		endTime = ISOToIgorSecs(AcquisitionStartTime[0]) + ElapsedTime[i]
		startTime = endTime - measeurment_time[i]
		
		wnote += "Detector : " + description[0] + "	 S/N " + detector_number[0]+"\r"
		wnote += "Pixel size : " + num2str(x_pixel_size[0]*1e6)+" [µm]" //+ " × "+ num2str(y_pixel_size[0]*1e6) + " [µm]"+"\r"
		wnote += "Sample name : " + sample_name[i]+"\r"
		wnote += "Ambient status : " + ambient_status[i] + "\r"
		wnote += "Wavelength : " + num2str(wavelength[i]*1e10)+" [Å]"+"\r"
		wnote += "SDD : " + num2str(SDD[i])+" [m]"+"\r"
		wnote += "Sample position : " + sample_position[i]+"\r"
		wnote += "Start time : "+ IgorSecsToTimeStamp(startTime) + "\r"
		wnote += "End time : " + IgorSecsToTimeStamp(endTime) + "\r"
		wnote += "Measeurment time : " + num2str(measeurment_time[i])+" [sec]"+"\r"
		if(WaveExists(averaged_frames))
			wnote += "Averaged frames : " + num2str(averaged_frames[i])+"\r"
		endif
		wnote += "Sample temperature : " + num2str(sample_temperature[i])+" [C]"+"\r"
		wnote += "Sample thickness : " + num2str(Sample_thickness[i]/10)+" [cm]"+"\r"	
		wnote += "Transmittance : " + num2str(transmittance[i]) + "\r"
		wnote += "flux_entering_sample : " + num2str(flux_entering_sample[i]) + " [cts]"+"\r"
		wnote += "flux_exiting_sample : " + num2str(flux_exiting_sample[i]) + " [cts]"+"\r"
		wnote += "detector_x_position : " + num2str(detector_x_position[i]) + " [m]" + "\r"
		wnote += "detector_y_position : " + num2str(detector_y_position[i]) + " [m]" + "\r"
		wnote += "Number of pixels in x : " + num2str(DimSize(target,0)) + "\r"
		wnote += "Number of pixels in y : " + num2str(DimSize(target,1)) + "\r"
		
		if (strlen(note(target)) == 0)
			Note target, wnote
		endif
		
		wnote = ""
	endfor
	
	Wave/Z SDDtype
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
	
//	String allwlist = wavelist("*",";","DIMS:1")
//	for(i=0; i< ItemsInList(allwlist);i+=1)
//		killwaves/Z $(StringFromList(i, allwlist))
//	endfor
	
	killwaves/Z imagestack

end

Function/S R2D_AddSequentialNumbers(strlist, flag)
	string strlist
	variable flag	//	0 to leave _0 as is when there is no _1, 1 to remove this mono _0.
	
	wave/T strings_w = ListToTextWave(strlist, ";")
	FindDuplicates/RT=key_w/FREE strings_w

	variable num_keys = DimSize(key_w, 0)
	Make/FREE/O/N=(num_keys) count_w = 0
	
	// add sequential number
	variable num_items = itemsinList(strlist)
	string new_strlist = ""
	variable i
	for(i=0; i<num_items; i++)
		string str = StringFromList(i, strlist)
		FindValue/TEXT=str/TXOP=4 key_w	// check which key this item string belongs to
		variable key_index = V_value
		new_strlist += str + "_" + num2str(count_w[key_index]) + ";"
		count_w[key_index] += 1 // add count to the count wave with corresponding index of the key
	endfor
	
	// an option to remove _0 if _0 is the only index for the str item
	if(flag == 1)
		string key
		for(key_index=0; key_index<num_keys; key_index++)
			if(count_w[key_index] == 1)	// count_w[i] == 1 means this key only has one item in the strlist
				key = key_w[key_index]
				new_strlist = ReplaceString(key + "_0", new_strlist, key)
			endif
		endfor
	endif
	
	return new_strlist
	
End

Function ISOToIgorSecs(isoStr)
    String isoStr
    Variable year, month, day, hour, minute, second
    Variable tzSign, tzHour, tzMin, tzOffset

    String datePart = StringFromList(0, isoStr, "T")
    String timeZonePart = StringFromList(1, isoStr, "T")

    // Remove timezone info
    Variable plusPos = strsearch(timeZonePart, "+", 0)
    Variable minusPos = strsearch(timeZonePart, "-", 0)
    Variable tzPos
    if (plusPos >= 0)
        tzPos = plusPos
        tzSign = 1
    else
        tzPos = minusPos
        tzSign = -1
    endif

    String timePart, tzString
    if (tzPos >= 0)
        timePart = timeZonePart[0, tzPos - 1]
        tzString = timeZonePart[tzPos, Inf]
        tzHour = str2num(StringFromList(0, tzString[1, Inf], ":"))
        tzMin  = str2num(StringFromList(1, tzString[1, Inf], ":"))
        tzOffset = tzSign * (tzHour * 3600 + tzMin * 60)
    else
        timePart = timeZonePart
        tzOffset = 0  // No timezone info, assume UTC
    endif

    // Parse date
    year  = str2num(StringFromList(0, datePart, "-"))
    month = str2num(StringFromList(1, datePart, "-"))
    day   = str2num(StringFromList(2, datePart, "-"))

    // Parse time
    hour   = str2num(StringFromList(0, timePart, ":"))
    minute = str2num(StringFromList(1, timePart, ":"))
    second = str2num(StringFromList(2, timePart, ":"))  // may include fraction

    Variable secs = date2secs(year, month, day) + hour*3600 + minute*60 + second
//    secs -= tzOffset  // Convert to UTC time
    return secs
End

Function/S IgorSecsToTimeStamp(secs)
    Variable secs

    // Get date and time strings
    String dateStr = Secs2Date(secs, -2)  // e.g., "1993-03-14"
    String timeStr = Secs2Time(secs, 3)     // e.g., "15:04:42"

    // Combine all into time stamp
    String TimeStampStr = dateStr + " " + timeStr
    return TimeStampStr
End


Function R2D_FillDataseetSAXSpoint()

	String Datasheet_Path = GetDatasheetPath()  // get path of the datasheet if exists. This func works in 1D and 2D folders.
	wave/T/Z datasheet = $Datasheet_Path
	If(!waveExists(datasheet))
		print "datasheet does not exist. cancel filling."
		return -1
	endif

	R2D_FillDataseet_worker("Sample Name", " : ", "\r", "SampleName", "text", Datasheet_Path)
	R2D_FillDataseet_worker("Measeurment time", " : ", "\r", "Time_s", "number", Datasheet_Path)
	R2D_FillDataseet_worker("Transmittance", " : ", "\r", "Trans", "number", Datasheet_Path)
	R2D_FillDataseet_worker("Sample thickness", " : ", "\r", "Thick_cm", "number", Datasheet_Path)

End

Function R2D_FillDataseet_worker(Key, KeySeparator, ListSeparator, DatasheetColName, format, Datasheet_Path)
	String Key
	String KeySeparator
	String ListSeparator
	String DatasheetColName
	String format
	String Datasheet_Path
	
//	String Datasheet_Path = GetDatasheetPath()  // get path of the datasheet if exists. This func works in 1D and 2D folders.
	wave/T datasheet = $Datasheet_Path
	String imagefolder = GetWavesDataFolder(datasheet,1)+":" // get the full path of the datafolder for datasheet

	String imagename
	String imagepath
	String target
	String image_note
	variable numInDatasheet = Dimsize(Datasheet, 0)
	variable val
	variable i
	For(i=0; i<numInDatasheet; i++)
		imagename = Datasheet[i][%ImageName]  // get imagename
		imagepath = imagefolder+imagename  // set image full path. the user may be in the image folder and 1d folder.
		image_note = note($imagepath)  // get note of the image
		target = StringByKey(key, image_note, KeySeparator, ListSeparator)  // get sample name in the note
		if(strlen(target) == 0 || numtype(strlen(target)) == 2)
			// do nothing
		else
			if(stringmatch(format, "number"))	// remove non-numeric characters
				val = str2num(target)
				target = num2str(val)
			endif
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


Function R2D_combine_extended_images()

	// load all wave names in current data folder
	string imglist = wavelist("*", ";", "DIMS:2")
	
	// create a list of keys
	// this function assume the last item in the name, separated by "_", is the sequential number
	variable num_images = itemsinList(imglist)
	string basename_list = ""
	variable i
	for(i=0; i<num_images; i++)
		string imagename = StringFromList(i,imglist)
		variable num_tag = itemsInList(imagename, "_")
		string basename = RemoveListItem(num_tag-1, imagename, "_")
		basename = RemoveEnding(basename)	// remove "_"
		basename_list +=  basename + ";"
	endfor
	
	wave/T basename_w = ListToTextWave(basename_list, ";")
	FindDuplicates/RT=key_w basename_w	// get key wave

	// combine the images with the same key (basename)
	// here we have three list (or 1D wave) for image names, imglist, basename_w (or list), key_w
	// imglist contains sequential number, basename_w does not contain sequential number, key_w is the basename without duplications.
	variable num_keys = numpnts(key_w)
	make/N=(num_keys)/O/FREE count_w
	
	// get the maximum index of each key
	for(i=0; i<num_keys; i++)
		string key = key_w[i]
		string matched_items = ListMatch(basename_list, key)
		variable num_matched = itemsInList(matched_items)
		count_w[i] = num_matched
	endfor
	
	variable name_index	// index regarding all images
	variable count	// index regarding the same basename
	for(i=0; i<num_keys; i++)
		name_index = 0 // reset index
		count = 0 // reset count
		make/N=(count_w[i])/FREE/O detector_x_pos_array
		make/N=(count_w[i])/FREE/O detector_y_pos_array
		Do
			FindValue/TEXT=key_w[i]/TXOP=4/S=(name_index) basename_w
			name_index = V_value
			
			if(name_index >= 0)	// if found
				// get x, y pos of detector
				imagename = StringFromList(name_index, imglist)
				wave img = $imagename
				string wnote = note(img)
				variable x_pos = Str2num( StringByKey("detector_x_position", wnote, " : ", "\r") )
				variable y_pos = Str2num( StringByKey("detector_y_position", wnote, " : ", "\r") )
				variable x_pixelnumber = Str2num( StringByKey("Number of pixels in x", wnote, " : ", "\r") )
				variable y_pixelnumber = Str2num( StringByKey("Number of pixels in y", wnote, " : ", "\r") )
				variable pixelsize = Str2num( StringByKey("Pixel size", wnote, " : ", "\r") )
				detector_x_pos_array[count] = x_pos
				detector_y_pos_array[count] = y_pos
//				print imagename + ": x = " + num2str(x_pos) + ", y = " + num2str(y_pos)
				name_index ++
				count ++
			endif
			
			if(name_index > num_images - 1 || name_index < 0)
				break
			endif
		While(1)
		
		// make an extended blank image
		variable extended_x_size = WaveMax(detector_x_pos_array)*1E6 - WaveMin(detector_x_pos_array)*1E6 + x_pixelnumber * pixelsize
		variable extended_y_size = WaveMax(detector_y_pos_array)*1E6 - WaveMin(detector_y_pos_array)*1E6 + y_pixelnumber * pixelsize
		variable extended_x_numOfpixels = floor(extended_x_size/pixelsize)
		variable extended_y_numOfpixels = floor(extended_y_size/pixelsize)
		make/O/N=(extended_x_numOfpixels,extended_y_numOfpixels) extended_image
		
		// assign each image to the extended one
//		extended_image[0][] = 
		
	endfor	
	
	
	// get the detector position of each image
	
	
	// 

End