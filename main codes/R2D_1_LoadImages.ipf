#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/////////////////////////////////
//////LOAD SELECTED IMAGES///////
/////////////////////////////////
Function/S R2D_LoadImages(extension, mode, overwrite, [folderPath])
	string extension	// only supports tiff and edf for now. 2023-04-08
	string mode			// "folder" or "files"
	variable overwrite	// 0 false, 1 true
	string folderPath	// ":" separated path to the folder. if provided, do not show a dialog.


	// Get file path list.
	// The codes differs based on "mode", "extension", and "folderPath".
	string filePaths = ""	// initialize file path list
	
	if(cmpstr(mode, "folder") == 0)	// "folder" mode
	
		// create a symbolic path of the image folder in the pc
		If(ParamIsDefault(folderPath))	// if folderPath is not provided
			NewPath/O/M="Select a folder" R2D_PCImageFolder  // create a new folderPath, user dialog
		Else  // if folderPath is provided
			NewPath/O R2D_PCImageFolder, folderPath  // load preset path from "folderPath" without showing a dialog
		Endif
		PathInfo R2D_PCImageFolder
		string R2D_PCImageFolder_str = S_path
		
		// get the list of all file paths in the selected folder
		string filenames = IndexedFile(R2D_PCImageFolder, -1, extension)
		if (strlen(filenames) == 0)
			Print "User cancelled"
			return filePaths		// Will be empty if user canceled
		endif
		filePaths = R2D_PCImageFolder_str+ replaceString(";", removeEnding(filenames), ";"+R2D_PCImageFolder_str) // change finemae to filepath
		
	elseif(cmpstr(mode, "files") == 0)	//"files" mode
	
		variable refNum
		string fileFilters = ""
		
		// set filefilters
		if(cmpstr(extension, ".tif") == 0)	// pf, rigaku, anton paar
			fileFilters = "Data Files (*.tif):.tif;"
		elseif(cmpstr(extension, ".edf") == 0)	// xenocs
			fileFilters = "Data Files (*.edf):.edf;"
		elseif(cmpstr(extension, ".asc") == 0)
			fileFilters = "Data Files (*.asc):.asc;"
		elseif(cmpstr(extension, ".txt") == 0)
			fileFilters = "Data Files (*.txt):.txt;"
		elseif(cmpstr(extension, ".dat") == 0)
			fileFilters = "Data Files (*.dat):.dat;"
		elseif(cmpstr(extension, ".mdat") == 0)	// sans-u main detector
			fileFilters = "Data Files (*.mdat):.mdat;"
		elseif(cmpstr(extension, ".sdat") == 0)	// sans-u pmt detector
			fileFilters = "Data Files (*.sdat):.sdat;"
		else
			Print "Something wrong happend in selecting file format."
			return filePaths
		endif
	
		// open a dialog and let user select the files, then get a list of selected files
		Open/D/R/MULT=1/F=fileFilters/M="Select one or more files" refNum // refNum is not used when /D exists but need to be supplied here.
		filePaths = ReplaceString("\r", S_fileName, ";")	//S_filename stores the selected files names separated by "\r"

		// if no files is selected, close this proceddure.
		if (strlen(filePaths) == 0)
			Print "User cancelled"
			return filePaths		// Will be empty if user canceled
		endif
				
	else
	
		print "Something wrong in the mode selection. Please check the codes."
		return filePaths
		
	endif
	
	
	// Load images and their headers, using "filePaths".
	// The codes differs based on "extension" and "overwrite" flag
 	string filepath
	variable numFilesSelected = ItemsInList(filePaths)
	variable i
	R2D_CreateImageList(1) // refresh imagelist
	
	if(cmpstr(extension, ".tif") == 0) // loading tiff images
		for(i=0; i<numFilesSelected; i+=1)
			filepath = StringFromList(i, filePaths) // Get the path of ith of selected waves.
			LoadTIFF(filepath, overwrite)
		endfor	
	elseif(cmpstr(extension, ".edf") == 0) // loading edf images
		for(i=0; i<numFilesSelected; i+=1)
			filepath = StringFromList(i, filePaths) // Get the path of ith of selected waves.
			LoadEDF(filepath, overwrite)
		endfor
	elseif(cmpstr(extension, ".dat") == 0 || cmpstr(extension, ".asc") == 0 || cmpstr(extension, ".txt") == 0) // loading txt images
		// the extension will be specified in the beginning of this function. 
		// the loading function below works similarly for these three extensions.
		for(i=0; i<numFilesSelected; i+=1)
			filepath = StringFromList(i, filePaths) // Get the path of ith of selected waves.
			LoadTEXTImage(filepath, overwrite)
		endfor	
	elseif(cmpstr(extension, ".mdat") == 0) // loading mdat images for SANS-U
		for(i=0; i<numFilesSelected; i+=1)
			filepath = StringFromList(i, filePaths) // Get the path of ith of selected waves.
			Load_SANSU_MainPSD_binary(filepath, overwrite)
		endfor
	elseif(cmpstr(extension, ".sdat") == 0) // loading mdat images for SANS-U
		for(i=0; i<numFilesSelected; i+=1)
			filepath = StringFromList(i, filePaths) // Get the path of ith of selected waves.
			Load_SANSU_PMT_binary(filepath, overwrite)
		endfor
	endif
	
 	Print "Image loading completed..."
 	
	R2D_CreateImageList(1) // create an imagelist with the name order

End

// load tiff
Static Function LoadTIFF(filepath, overwrite)
	string filepath
	variable overwrite
	
	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule
	string header
	
	// Load the tiff image with overwrite flag
	If(overwrite == 1) // if overwrite is enabled, 
		ImageLoad/T=tiff/Q/O/RAT/N=$ImageName filepath
	Elseif(overwrite == 0) // if overwrite is disabled
		SVAR ImageList = :Red2DPackage:U_ImageList
		string resultStr = ListMatch(ImageList, ImageName) // check if the image is new
		If(strlen(resultStr) == 0)  // if the image is new, load it.
			ImageLoad/T=tiff/Q/RAT/N=$ImageName filepath
		Else	// skip loading and set filename to empty to skip following file adjustment and header loading.
			fileName =""  
		Endif
	Endif
	
	// Adjust loaded image
	If(strlen(filename) > 0)	// if the file is loaded
		// Modify images
		wave ImageWave = $ImageName	 // get wave
		Redimension/S ImageWave	 // change data type to single float. 
		Multithread ImageWave[][] = ImageWave[p][q] <= -1 ? NaN : ImageWave[p][q] // negative values to NaN; pixels with NaN are automatically masked
		
		// Append tag to the wavenote
		header = "" // initialize header
		wave/T tiftag = :Tag0:T_Tags // get tag
		header += FindByKeyInTiffTag("DATETIME", tiftag) + "\r"
		header += FindByKeyInTiffTag("ARTIST", tiftag) + "\r"
		header += FindByKeyInTiffTag("MODEL", tiftag) + "\r"
		header += FindByKeyInTiffTag("SOFTWARE", tiftag) + "\r"
		header += FindByKeyInTiffTag("IMAGEDESCRIPTION", tiftag) + "\r"
		header = ReplaceString("\r\n", header, "\r")	// cleanup whitespace
		Note/K ImageWave, header  // note the wave with the header
		KillDataFolder/Z :Tag0
		
		Print fileName
		
	Endif
End

// load tiff tag by key
Static Function/S FindByKeyInTiffTag(key, tiftag)
	string key
	wave/T tiftag
	
	variable rowsInTag = DimSize(tiftag,0)
	variable col, row
	string buffer = ""

	FindValue/TEXT=key tiftag
	if(V_value != -1)
		col=floor(V_value/rowsInTag)
		row=V_value-col*rowsInTag
		sprintf buffer, "%s", tiftag[row][%Value]
	Endif
	
	return buffer

End

// load edf
Static Function LoadEDF(filepath, overwrite)
	string filepath
	variable overwrite
	
	// set basic information
	
	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule
	
	variable refnum
	string header
	variable headerSize
	variable XSize, YSize
		
	// load header to get the essential information to load the binary data
	open/R refNum as filepath
	header = "" // initialize header
	FReadLine/N=4096/T="}" refNum, header	// 512 bits or 4096 bytes is the maximum header length of edf.
	variable apparent_tag_num = ItemsInList(header)	// get apparent number of tags
	header = RemoveListItem(apparent_tag_num-1, header)	// remove the last apparent tag
	header = ReplaceString("{\n", header, "")	// delete the begining mark of header
	header = ReplaceString("\n", header, "\r") // remove \n and use \r as separator. \r is igor's default
	header = ReplaceString(" ;", header, "") // remove ;
	
	headerSize = NumberByKey("EDF_HeaderSize", header, " = ", "\r") // edf header ends with }\n, but FReadLine /T only recognize 2bytes, "}". So I need to get headerSize from header key.
	XSize = NumberByKey("Dim_1", header, " = ", "\r")
	YSize = NumberByKey("Dim_2", header, " = ", "\r")
	
	// Load the edf image with overwrite flag
	If(overwrite == 1) // if overwrite is enabled, 
		GBLoadWave/O/B=1/T={2,2}/S=(headerSize)/W=1/A/Q filepath
	Elseif(overwrite == 0) // if overwrite is disabled
		SVAR ImageList = :Red2DPackage:U_ImageList
		string resultStr = ListMatch(ImageList, ImageName) // check if the image is new
		If(strlen(resultStr) == 0)  // if the image is new, load it.
			GBLoadWave/B=1/T={2,2}/S=(headerSize)/W=1/A/Q filepath
		Else	// skip loading and set filename to empty to skip following file adjustment and header loading.
			fileName =""  
		Endif
	Endif
	
	// Adjust loaded image
	If(strlen(filename) > 0)	// if the file is loaded
		// Modify images
		string LoadedWaveName = StringFromList(0,S_waveNames)	// GBLoadWave will add a sequential number to the wavename. So I need to use S_waveNames to identify the true wave name.
		Duplicate/O $LoadedWaveName, $ImageName
		KillWaves/Z $LoadedWaveName
		wave ImageWave = $ImageName	 // get wave
		Redimension/N=(XSize,YSize) ImageWave //
		Multithread ImageWave[][] = ImageWave[p][q] <= -1 ? NaN : ImageWave[p][q] // negative values to NaN; pixels with NaN are automatically masked
		
		// Append tag to the wavenote
		Note/K ImageWave, header
		
		Print fileName
		
	Endif

End

// load text images, including .txt, .dat, .asc
Static Function LoadTEXTImage(filepath, overwrite)
	string filepath
	variable overwrite
	
	// set basic information
	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule
	
	variable refnum
	string header = ""	// initialize
	string buffer = "" // initialize
		
	// Load the Text image with overwrite flag
	If(overwrite == 1) // if overwrite is enabled, 
		LoadWave/G/D/O/M/A filepath  // load images
	Elseif(overwrite == 0) // if overwrite is disabled
		SVAR ImageList = :Red2DPackage:U_ImageList
		string resultStr = ListMatch(ImageList, ImageName) // check if the image is new
		If(strlen(resultStr) == 0)  // if the image is new, load it.
			LoadWave/G/D/M/A filepath  // load images
		Else	// skip loading and set filename to empty to skip following file adjustment and header loading.
			fileName =""  
		Endif
	Endif
	
	// Adjust loaded image
	If(strlen(filename) > 0)	// if the file is loaded
		// Modify images
		string LoadedWaveName = StringFromList(0,S_waveNames)	// GBLoadWave will add a sequential number to the wavename. So I need to use S_waveNames to identify the true wave name.
		Duplicate/O $LoadedWaveName, $ImageName
		KillWaves/Z $LoadedWaveName
		wave ImageWave = $ImageName	 // get wave
		Redimension/S ImageWave // change from integer to single float
		Multithread ImageWave[][] = ImageWave[p][q] <= -1 ? NaN : ImageWave[p][q] // negative values to NaN; pixels with NaN are automatically masked
		
		// Append tag to the wavenote
		Open/R refNum as filepath
		variable j = 0
		Do
			FReadLine refNum, buffer //Read one line each until find the specified string
			if(strlen(buffer) <= 1)	// 0 does not work for a line with only \r\n. so I set 1 instead.
			// this break statement is desgined for SANS-U dat files. New break statement may be required for the other text images.
				break
			endif
			header += buffer
			j++
		while(j<100)  // 100 is set to avoid loading all lines.
		Note/K ImageWave, header
		
		Print fileName
		
	Endif

End

// load sans-u mdat binary
Static Function Load_SANSU_MainPSD_binary(filepath, overwrite)
	string filepath
	variable overwrite
	
	// set basic information
	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule
	
	variable refnum
	string header = ""	// initialize
	string buffer = "" // initialize
	variable headerSize = 2056
		
	// Load the Text image with overwrite flag
	If(overwrite == 1) // if overwrite is enabled, 
		GBLoadWave/O/T={96,2}/S=(headerSize)/W=1 filepath  // load images 127*128*4=65024 bytes; 67080-65024=2056
		// 128*128*4=65536 bytes; 67080-65536=1544 bytes. I do not know why but sans-u saving 2d data as 127*128.
	Elseif(overwrite == 0) // if overwrite is disabled
		SVAR ImageList = :Red2DPackage:U_ImageList
		string resultStr = ListMatch(ImageList, ImageName) // check if the image is new
		If(strlen(resultStr) == 0)  // if the image is new, load it.
			GBLoadWave/T={96,2}/S=(headerSize)/W=1 filepath  // load images
		Else	// skip loading and set filename to empty to skip following file adjustment and header loading.
			fileName =""  
		Endif
	Endif
	
	// Adjust loaded image
	If(strlen(filename) > 0)	// if the file is loaded
		// Modify images
		string LoadedWaveName = StringFromList(0,S_waveNames)	// GBLoadWave will add a sequential number to the wavename. So I need to use S_waveNames to identify the true wave name.
		Duplicate/O $LoadedWaveName, $ImageName
		KillWaves/Z $LoadedWaveName
		wave ImageWave = $ImageName	 // get wave
		Redimension/N=(128,127) ImageWave // 127 rows and 128 columns in .dat file. .mdat file seems transposed.
		MatrixOP/O/FREE outWave = ImageWave^t	// transpose the image
		Duplicate/O outWave ImageWave
		Multithread ImageWave[][] = ImageWave[p][q] <= -1 ? NaN : ImageWave[p][q] // negative values to NaN; pixels with NaN are automatically masked
		
		// Append tag to the wavenote
		Open/R refNum as filepath
		header = "" // initialize header
		FReadLine/N=(headerSize) refNum, header
	
		Note/K ImageWave, header
		
		Print fileName
		
	Endif

End

// load sans-u sdat binary
Static Function Load_SANSU_PMT_binary(filepath, overwrite)
	string filepath
	variable overwrite
	
	// set basic information
	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule
	
	variable refnum
	string header = ""	// initialize
	string buffer = "" // initialize
	variable headerSize = 2060
		
	// Load the Text image with overwrite flag
	If(overwrite == 1) // if overwrite is enabled, 
		GBLoadWave/O/T={96,2}/S=(headerSize)/W=1 filepath  // load images
	Elseif(overwrite == 0) // if overwrite is disabled
		SVAR ImageList = :Red2DPackage:U_ImageList
		string resultStr = ListMatch(ImageList, ImageName) // check if the image is new
		If(strlen(resultStr) == 0)  // if the image is new, load it.
			GBLoadWave/T={96,2}/S=(headerSize)/W=1 filepath  // load images
		Else	// skip loading and set filename to empty to skip following file adjustment and header loading.
			fileName =""  
		Endif
	Endif
	
	// Adjust loaded image
	If(strlen(filename) > 0)	// if the file is loaded
		// Modify images
		string LoadedWaveName = StringFromList(0,S_waveNames)	// GBLoadWave will add a sequential number to the wavename. So I need to use S_waveNames to identify the true wave name.
		Duplicate/O $LoadedWaveName, $ImageName
		KillWaves/Z $LoadedWaveName
		wave ImageWave = $ImageName	 // get wave
		Redimension/N=(256,256) ImageWave
		Multithread ImageWave[][] = ImageWave[p][q] <= -1 ? NaN : ImageWave[p][q] // negative values to NaN; pixels with NaN are automatically masked
		
		// Append tag to the wavenote
		Open/R refNum as filepath
		header = "" // initialize header
		FReadLine/N=(headerSize) refNum, header
		header = ReplaceString("      ", header, "\r")
		header = ReplaceString("     ", header, "\r")
		header = ReplaceString("    ", header, "\r")
		header = ReplaceString("   ", header, "\r")
		header = ReplaceString("  ", header, "\r")
		header = RemoveFromList("",header,"\r")
	
		Note/K ImageWave, header
		
		Print fileName
		
	Endif

End




////////////////////////
// ONLY FOR auto process 2023-04-08.
////////////////////////

/// LOAD IMAGES IN ALL SUBFOLDERS
Function R2D_LoadAllTIFF([path,overwrite])
	string path
	variable overwrite
	
	R2D_CreateImageList(2)  // refresh the imagelist. The imagelist is used to check if the target image exists in igor.
	
	If(ParamIsDefault(path))	// path not specified
		NewPath/O R2D_PCImageFolder  // create a new path, user dialog
	Else  // path specified
		NewPath/O R2D_PCImageFolder, path  // load preset path from "path"
	Endif 
	
	If(V_flag == 0)
		Print "Loading images..."
		If(ParamIsDefault(overwrite) || overwrite == 0)  // if do not overwrite
			String/G :Red2DPackage:U_NewImageList = "" // a list to store the names of newly loaded files. Not in use 2021-04-15.
			
			ImageLoadSubFolders("R2D_PCImageFolder", ".tif", 1, 0, 0, 0)  // no overwrite, no add files
			
			Print "New images were loaded. Existing images were skiped."	
		Else  // if overwrite
			ImageLoadSubFolders("R2D_PCImageFolder", ".tif", 1, 0, 1, 0)  // overwrite, no add files
			Print "All images were loaded. Existing images were overwritten."	
		Endif
		
	Else
		Print "User canceled"
		Abort	
	Endif
	
	R2D_CreateImageList(1) // create an imagelist (a textwave and a list_string) with the name order
	
	PathInfo/S R2D_PCImageFolder  // set default symbolic path to main folder.

End


/// LOAD IMAGES IN ALL SUBFOLDERS and add images within the same subfolders
Function R2D_LoadAllTIFF_addSubfolders()
	
	NewPath/O R2D_PCImageFolder
	If(V_flag == 0)
		Print "Loading images..."
		ImageLoadSubFolders("R2D_PCImageFolder", ".tif", 1, 0, 1, 1)  // add files
		Print "Completed"	
	Else
		Print "User canceled"
		Abort
	Endif
	
	R2D_CreateImageList(2) // create an imagelist with the order date created
	
	PathInfo/S R2D_PCImageFolder  // set default path to main folder.

End


// A script from Igor forum. I have modified some parts.
//  ImageLoadSubFolders(pathName, extension, recurse, level)
//  Shows how to recursively find all files in a folder and subfolders.
//  pathName is the name of an Igor symbolic path that you created using NewPath or the Misc->New Path menu item.
//  extension is a file name extension like ".txt" or "????" for all files.
//  recurse is 1 to recurse or 0 to list just the top-level folder.
//  level is the recursion level - pass 0 when calling PrintFoldersAndFiles.
Static Function ImageLoadSubFolders(pathName, extension, recurse, level, overwrite, add)
    string pathName     // Name of symbolic path in which to look for folders and files.
    string extension            // File name extension (e.g., ".txt") or "????" for all files.
    variable recurse        // True to recurse (do it for subfolders too).
    variable level          // Recursion level. Pass 0 for the top level.
    variable overwrite  // Overwrite existing files. 1 for ture (overwrite), 0 for false.
    variable add 			// Add files (1) or not (0)
    
    variable folderIndex, fileIndex
    Wave/T ImageList = :Red2DPackage:ImageList
    SVAR NewImageList = :Red2DPackage:U_NewImageList
    
    // Build a prefix (a number of tabs to indicate the folder level by indentation)
    folderIndex = 0
    do
        if (folderIndex >= level)
            break
        endif
        folderIndex += 1
    while(1)	// This would loop forever until "break" actives.
    
    string path
    PathInfo $pathName              // Sets S_path
    path = S_path
    
    string header
    string file_path
		
    fileIndex = 0
    do
        string fileName
        string refname
        string LoadedWaveList
        Wave/Z Added
        fileName = IndexedFile($pathName, fileIndex, extension)  // return index-th filename in the specified folder
        
        /// Loop exit statemement
		if (strlen(fileName) == 0) // if no more file exists, get out the do-while-loop.

			//////////////////////////
			///A block for adding iamges///
			if(add == 1 && fileIndex > 0)  // change names of the added waves. fileindex > 0 is used to avoid NaN error.
				// Sort wave names and get the first name in alphabet order.
				refname = StringFromList(0, SortList(LoadedWaveList))
        			
				// Check if the files are created by SAXSpoint2.0 (Anton Paar) auto-experiments
				// You can add other special rules here to remove unnecessary characters.
				string str1 = refname[strlen(refname)-14,strlen(refname)-9]
				if(Cmpstr(str1,"_Frame", 1) == 0)
					refname = refname[0, strlen(refname)-15]
				endif

				Duplicate/O/D Added, $refname  // save the combined wave as refname
				KillWaves/Z Added  // delete the original combined wave
				Print num2Str(fileIndex) + " files were added and saved as " + refname
   	  		endif
			////////////////////////
        		
        break
		endif

		/// Load images
		string ImageName = R2D_CleanupName(fileName) // Remove extension and unnecessary characters
		If(overwrite == 0) // skip existing
			FindValue/TEXT=ImageName ImageList  // check if the target image already existing in igor
			If(V_value == -1)  // if the target image has not been loaded
				ImageLoad/T=tiff/Q/P=$pathName/N=$ImageName fileName  // load a image
				Print fileName
				NewImageList = AddListItem(ImageName, NewImageList)
			Else
				fileName =""  // make the file name empty to skip the following process.
			Endif
		Else // overwrite
			ImageLoad/T=tiff/Q/O/P=$pathName/N=$ImageName fileName  // load a image
			Print fileName
		Endif
			
			
		If(strlen(filename) > 0)  // if filename is not empty
			
			// Convert 32bit signed integer to single float. This is for the use of NaN.
  			wave refwave = $ImageName  
			Redimension/S refwave
			Multithread refwave[][] = refwave[p][q] <= -1 ? NaN : refwave[p][q]
			file_path = S_path + S_fileName  // set the file full path
			header = R2D_GetHeader_TIFF(file_path)  // read the header
			Note/K refwave, header  // note the wave with the heade
		
			// Add waves from the same subfolder.
			If(add == 1)
				If(fileIndex == 0)	// make the first loaded wave as the reference wave to add
					Duplicate/O/D $ImageName, Added
					LoadedWaveList = ""
					LoadedWaveList = AddListItem(ImageName, LoadedWaveList)
					Killwaves/Z $ImageName				
				Else
					Wave Toadd = $ImageName
					MultiThread Added += Toadd
					KillWaves/Z Toadd
					LoadedWaveList = AddListItem(ImageName, LoadedWaveList)
				Endif
			Endif
		Endif
			
        fileIndex += 1
    while(1)

    
    if (recurse)                                    // Do we want to go into subfolder?
        folderIndex = 0
        do
            path = IndexedDir($pathName, folderIndex, 1)	// (NameOfParentSymbolicPath, index of subfolder, bitwise parameter:0, i.e.1 = full path)
            if (strlen(path) == 0)
                break                           // No more folders
            endif

            string subFolderPathName = "tempPrintFoldersPath_" + num2istr(level+1)
            
            // Now we get the path to the new parent folder
            string subFolderPath
            subFolderPath = path
            
            NewPath/Q/O $subFolderPathName, subFolderPath
            ImageLoadSubFolders(subFolderPathName, extension, recurse, level+1, overwrite, add)
            KillPath/Z $subFolderPathName
            
            folderIndex += 1
        while(1)	// This would loop forever until "break" actives.
    endif
    
End

Function/S R2D_GetHeader_TIFF(path)
	string path // file path
//	variable endline  // terminal line for the header, line number starts from zero.
//	variable mode  // 0 for general text, 1 for tiff (Pilatus), 2 for edf (Xenocs), maybe 3 for Anton Paar, and 4 for Rigaku
	
	string buffer
	variable refNum
	
	Open/R refNum as path
	string header = ""
	
	ImageLoad/T=tiff/Q/O/RTIO path
	wave/T tiftag = :Tag0:T_Tags
	variable rowsInTag = DimSize(tiftag,0)
	variable col, row
	
	FindValue/TEXT="MODEL" tiftag
	if(V_value != -1)
	col=floor(V_value/rowsInTag)
	row=V_value-col*rowsInTag
	sprintf buffer, "%s", tiftag[row][%Value]  // the tag contains null bytes, which can be removed by sprintf
	header += buffer+"\r"
	Endif
	
	FindValue/TEXT="SOFTWARE" tiftag
	if(V_value != -1)
	col=floor(V_value/rowsInTag)
	row=V_value-col*rowsInTag
	sprintf buffer, "%s", tiftag[row][%Value]
	header += buffer+"\r"
	Endif
	
	FindValue/TEXT="DATETIME" tiftag
	if(V_value != -1)
	col=floor(V_value/rowsInTag)
	row=V_value-col*rowsInTag
	sprintf buffer, "%s", tiftag[row][%Value]
	header += buffer+"\r"
	
	Endif
	
	FindValue/TEXT="IMAGEDESCRIPTION" tiftag
	if(V_value != -1)
	col=floor(V_value/rowsInTag)
	row=V_value-col*rowsInTag
	sprintf buffer, "%s", tiftag[row][%Value]
	header += buffer+"\r"
	header = ReplaceString("\r\n", header, "\r")
	Endif
	
	KillDataFolder/Z :Tag0
	
	return header

End