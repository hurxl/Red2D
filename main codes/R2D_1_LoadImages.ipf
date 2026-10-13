#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// [NEW 2026-10-13] Fixed numbers of the file formats. Change them here if a format changes.
static Constant kEDF_MaxHeaderBytes = 4096	// edf: maximum header length (512 bits or 4096 bytes)
static Constant kSANSU_MainHeaderBytes = 2056	// sans-u .mdat: 67080 bytes - 127*128*4 bytes of data
static Constant kSANSU_MainRows = 128	// sans-u .mdat: data is 128 x 127 in the file, transposed after loading
static Constant kSANSU_MainCols = 127
static Constant kSANSU_PMTHeaderBytes = 2060	// sans-u .sdat
static Constant kSANSU_PMTSize = 256	// sans-u .sdat: data is 256 x 256

// *** Load images common part
Function/S R2D_LoadImages(extension, mode, overwrite, [folderPath])
	string extension	// tif, edf, asc, txt, dat, mdat, sdat 2026-10-13
	string mode			// "folder", "files", "recursive" 2026-10-13
	variable overwrite	// 0 false, 1 true
	string folderPath	// ":" separated path to the folder. if provided, do not show a dialog.
	
	// prepare common strings and variables
//	string R2D_PCImageFolder_str	// [UNUSED 2026-10-13] only used by the old "folder" mode file list
	string filePaths = ""	// initialize file path list
	variable numLoaded = 0	// [NEW 2026-10-13] number of loaded images, for the message at the end

	// [NEW 2026-10-13] Check the extension once, before showing any dialog. GetFileFilter returns "" for unsupported extensions.
	string fileFilters = GetFileFilter(extension)
	if(strlen(fileFilters) == 0)
		Print "Unsupported extension: " + extension
		return filePaths
	endif

	// Get file path list.	The codes differs based on "mode", "extension", and "folderPath".
//	if(cmpstr(mode, "folder") == 0)	// "folder" mode	// [REPLACED 2026-10-13]
	if(cmpstr(mode, "folder") == 0 || cmpstr(mode, "recursive") == 0)	// [NEW 2026-10-13] "folder" and "recursive" modes share this code. Both use LoadImagesInFolder.
		// create a symbolic path of the image folder in the pc
		If(ParamIsDefault(folderPath))	// if folderPath is not provided
			NewPath/O/M="Select a folder" R2D_PCImageFolder  // create a new folderPath, user dialog
		Else  // if folderPath is provided
			NewPath/O R2D_PCImageFolder, folderPath  // load preset path from "folderPath" without showing a dialog
		Endif
		If(V_flag != 0)	// [NEW 2026-10-13] user cancelled the dialog. Without this, the previously selected folder was loaded.
			Print "User cancelled"
			return filePaths
		Endif
		// [UNUSED 2026-10-13] LoadImagesInFolder lists the files in the folder itself
//		PathInfo R2D_PCImageFolder
//		R2D_PCImageFolder_str = S_path
//
//		// get the list of all file paths in the selected folder
//		string filenames = IndexedFile(R2D_PCImageFolder, -1, extension)
//		if (strlen(filenames) == 0)
//			Print "No " + extension + " files in the selected folder"	// [NEW 2026-10-13]
//			return filePaths		// empty list
//		endif
//		filePaths = R2D_PCImageFolder_str+ replaceString(";", removeEnding(filenames), ";"+R2D_PCImageFolder_str) // change finemae to filepath

		// [NEW 2026-10-13] moved from the old "recursive" branch below
		variable recurse = (cmpstr(mode, "recursive") == 0)	// [NEW 2026-10-13] 0: only the selected folder ("folder"), 1: also all subfolders ("recursive")
//		ImageLoadSubFolders("R2D_PCImageFolder", extension, recurse, 0, overwrite, 0)	// [NEW 2026-10-13] no add files	// [REPLACED 2026-10-13] renamed; now returns the number of loaded images
		numLoaded = LoadImagesInFolder("R2D_PCImageFolder", extension, recurse, 0, overwrite, 0)	// [NEW 2026-10-13] arguments: (path, extension, recurse, level, overwrite, add)
		// [REPLACED 2026-10-13] moved to the shared ending at the bottom of this function
//		If(overwrite)
//			Print "All images were loaded. Existing images were overwritten."
//		Else
//			Print "New images were loaded. Existing images were skipped."
//		Endif
//
//		R2D_CreateImageList(1) // create an imagelist with the name order
		PathInfo/S R2D_PCImageFolder  // set default symbolic path to main folder.

//		return ""	// [UNUSED 2026-10-13] all modes now continue to the shared ending

	elseif(cmpstr(mode, "files") == 0)	//"files" mode
		variable refNum
		// [REPLACED 2026-10-13] by GetFileFilter at the top of this function
//		string fileFilters = ""
//
//		// set filefilters
//		if(cmpstr(extension, ".tif") == 0)	// pf, rigaku, anton paar
//			fileFilters = "Data Files (*.tif, *.tiff):.tif,.tiff;"
//		elseif(cmpstr(extension, ".edf") == 0)	// xenocs
//			fileFilters = "Data Files (*.edf):.edf;"
//		elseif(cmpstr(extension, ".asc") == 0)
//			fileFilters = "Data Files (*.asc):.asc;"
//		elseif(cmpstr(extension, ".txt") == 0)
//			fileFilters = "Data Files (*.txt):.txt;"
//		elseif(cmpstr(extension, ".dat") == 0)
//			fileFilters = "Data Files (*.dat):.dat;"
//		elseif(cmpstr(extension, ".mdat") == 0)	// sans-u main detector
//			fileFilters = "Data Files (*.mdat):.mdat;"
//		elseif(cmpstr(extension, ".sdat") == 0)	// sans-u pmt detector
//			fileFilters = "Data Files (*.sdat):.sdat;"
//		else
//			Print "Something wrong happend in selecting file format."
//			return filePaths
//		endif

		// open a dialog and let user select the files, then get a list of selected files
		Open/D/R/MULT=1/F=fileFilters/M="Select one or more files" refNum // refNum is not used when /D exists but need to be supplied here.
		filePaths = ReplaceString("\r", S_fileName, ";")	//S_filename stores the selected files names separated by "\r"

		// if no files is selected, close this proceddure.
		if (strlen(filePaths) == 0)
			Print "User cancelled"
			return filePaths		// Will be empty if user canceled
		endif

		// [NEW 2026-10-13] moved here from below the if-elseif block. Load each selected file.
		string filepath
		variable numFilesSelected = ItemsInList(filePaths)
		variable i
		for(i=0; i<numFilesSelected; i+=1)	// one loop for every extension. LoadOneImage picks the loader.
			filepath = StringFromList(i, filePaths) // Get the path of ith of selected waves.
//			LoadOneImage(filepath, extension, overwrite)	// [REPLACED 2026-10-13]
			numLoaded += LoadOneImage(filepath, extension, overwrite)	// [NEW 2026-10-13] count loaded images
		endfor

	// [REPLACED 2026-10-13] merged into the "folder" branch above. "recursive" mode now never reaches this branch.
//	elseif(cmpstr(mode, "recursive") == 0)	// "recursive" mode
//		// create a symbolic path of the image folder in the pc
//		If(ParamIsDefault(folderPath))	// if folderPath is not provided
//			NewPath/O/M="Select a folder" R2D_PCImageFolder  // create a new folderPath, user dialog
//		Else  // if folderPath is provided
//			NewPath/O R2D_PCImageFolder, folderPath  // load preset path from "folderPath" without showing a dialog
//		Endif
//
//		If(V_flag != 0)	// user cancelled the dialog
//			Print "User cancelled"
//			return ""
//		Endif
//		ImageLoadSubFolders("R2D_PCImageFolder", extension, 1, 0, overwrite, 0)
//
//		// ImageLoadSubFolders("R2D_PCImageFolder", ".tif", 1, 0, 1, 0)  // overwrite, no add files
//		// Print "All images were loaded. Existing images were overwritten."
//		If(overwrite)
//			Print "All images were loaded. Existing images were overwritten."
//		Else
//			Print "New images were loaded. Existing images were skipped."
//		Endif
//	
////		R2D_LoadAllTIFF(path = R2D_PCImageFolder_str, overwrite = overwrite)
//		
//		R2D_CreateImageList(1) // create an imagelist with the name order
//		PathInfo/S R2D_PCImageFolder  // set default symbolic path to main folder.
//		
//		return ""
			
	else
	
		print "Something wrong in the mode selection. Please check the codes."
		return filePaths
		
	endif
	
	
	// [REPLACED 2026-10-13] moved into the "files" branch above
//	// Load images and their headers, using "filePaths".
//	// [NEW 2026-10-13] Only "files" mode reaches here. "folder" and "recursive" modes return above.
//	// The codes differs based on "extension" and "overwrite" flag
// 	string filepath
//	variable numFilesSelected = ItemsInList(filePaths)
//	variable i
////	R2D_CreateImageList(1) // refresh imagelist	// [UNUSED 2026-10-13] all loaders check existing images with WaveExists, not the image list
//
//	for(i=0; i<numFilesSelected; i+=1)	// [NEW 2026-10-13] one loop for every extension. LoadOneImage picks the loader.
//		filepath = StringFromList(i, filePaths) // Get the path of ith of selected waves.
//		LoadOneImage(filepath, extension, overwrite)
//	endfor

	// [REPLACED 2026-10-13] by the loop above
//	if(cmpstr(extension, ".tif") == 0) // loading tiff images
//		for(i=0; i<numFilesSelected; i+=1)
//			filepath = StringFromList(i, filePaths) // Get the path of ith of selected waves.
//			LoadTIFF(filepath, overwrite)
//		endfor
//	elseif(cmpstr(extension, ".edf") == 0) // loading edf images
//		for(i=0; i<numFilesSelected; i+=1)
//			filepath = StringFromList(i, filePaths) // Get the path of ith of selected waves.
//			LoadEDF(filepath, overwrite)
//		endfor
//	elseif(cmpstr(extension, ".dat") == 0 || cmpstr(extension, ".asc") == 0 || cmpstr(extension, ".txt") == 0) // loading txt images
//		// the extension will be specified in the beginning of this function.
//		// the loading function below works similarly for these three extensions.
//		for(i=0; i<numFilesSelected; i+=1)
//			filepath = StringFromList(i, filePaths) // Get the path of ith of selected waves.
//			LoadTEXTImage(filepath, overwrite)
//		endfor
//	elseif(cmpstr(extension, ".mdat") == 0) // loading mdat images for SANS-U
//		for(i=0; i<numFilesSelected; i+=1)
//			filepath = StringFromList(i, filePaths) // Get the path of ith of selected waves.
//			Load_SANSU_MainPSD_binary(filepath, overwrite)
//		endfor
//	elseif(cmpstr(extension, ".sdat") == 0) // loading mdat images for SANS-U
//		for(i=0; i<numFilesSelected; i+=1)
//			filepath = StringFromList(i, filePaths) // Get the path of ith of selected waves.
//			Load_SANSU_PMT_binary(filepath, overwrite)
//		endfor
//	endif
	
	// [NEW 2026-10-13] Same ending for all modes
// 	Print "Image loading completed..."	// [REPLACED 2026-10-13] by the overwrite / skip messages below
	// [REPLACED 2026-10-13] by the messages below, which include the number of loaded images
//	If(overwrite)
//		Print "All images were loaded. Existing images were overwritten."
//	Else
//		Print "New images were loaded. Existing images were skipped."
//	Endif
	If(overwrite)	// [NEW 2026-10-13]
		Print num2str(numLoaded) + " images were loaded. Existing images were overwritten."
	Else
		Print num2str(numLoaded) + " new images were loaded. Existing images were skipped."
	Endif

	R2D_CreateImageList(1) // create an imagelist with the name order

	return filePaths	// [NEW 2026-10-13] selected file paths in "files" mode, empty in "folder" and "recursive" modes
End

// *** Load one image at a time

//// [NEW 2026-10-13] Load one image with the loader for its extension. Used by ImageLoadSubFolders.	// [REPLACED 2026-10-13]
// [NEW 2026-10-13] Load one image with the loader for its extension. Used by all modes: LoadImagesInFolder ("folder", "recursive") and R2D_LoadImages ("files").
// Each extension has its own loader below. To support a new extension, write a loader and add a case here.
// Returns 1 if the image was loaded, 0 if skipped or the extension is not supported.
Static Function LoadOneImage(filepath, extension, overwrite)
	string filepath
	string extension
	variable overwrite

	strswitch(extension)
		case ".tif":
			return LoadTIFF(filepath, overwrite)
		case ".edf":
			return LoadEDF(filepath, overwrite)
		case ".dat":
		case ".asc":
		case ".txt":
			return LoadTEXTImage(filepath, overwrite)
		case ".mdat":
			return Load_SANSU_MainPSD_binary(filepath, overwrite)
		case ".sdat":
			return Load_SANSU_PMT_binary(filepath, overwrite)
		default:
			Print "Unsupported extension: " + extension
			return 0
	endswitch
End

// [NEW 2026-10-13] File-dialog filter for each supported extension. Returns "" if the extension is not supported.
// R2D_LoadImages uses it to check the extension before any dialog, and for the "files" dialog.
// When adding a new extension, add it here and in LoadOneImage above.
Static Function/S GetFileFilter(extension)
	string extension

	strswitch(extension)
		case ".tif":	// pf, rigaku, anton paar
			return "Data Files (*.tif, *.tiff):.tif,.tiff;"
		case ".edf":	// xenocs
			return "Data Files (*.edf):.edf;"
		case ".asc":
			return "Data Files (*.asc):.asc;"
		case ".txt":
			return "Data Files (*.txt):.txt;"
		case ".dat":
			return "Data Files (*.dat):.dat;"
		case ".mdat":	// sans-u main detector
			return "Data Files (*.mdat):.mdat;"
		case ".sdat":	// sans-u pmt detector
			return "Data Files (*.sdat):.sdat;"
	endswitch
	return ""
End

// [NEW 2026-10-13] Shared helper for the loaders that use GBLoadWave or LoadWave with /A.
// /A gives the loaded wave an unused automatic name (e.g. wave0). This renames it to ImageName.
// Pass StringFromList(0, S_waveNames): S_waveNames is a local variable of the function that called GBLoadWave/LoadWave.
Static Function/WAVE RenameLoadedWave(loadedName, ImageName)
	string loadedName
	string ImageName

	Duplicate/O $loadedName, $ImageName
	KillWaves/Z $loadedName
	wave ImageWave = $ImageName
	return ImageWave
End

// [NEW 2026-10-13] Shared last steps of the loaders (except LoadTIFF, which uses "< 0" instead of "<= -1").
// Negative values to NaN, header to the wave note, print the file name.
Static Function FinishImage(ImageWave, header, fileName)
	wave ImageWave
	string header
	string fileName

	Multithread ImageWave[][] = ImageWave[p][q] <= -1 ? NaN : ImageWave[p][q] // negative values to NaN; pixels with NaN are automatically masked
	Note/K ImageWave, header	// note the wave with the header
	Print fileName
End

// load tiff
//// [NEW 2026-10-13] All tiff loading goes through this function (also called by ImageLoadSubFolders).	// [REPLACED 2026-10-13]
//// [NEW 2026-10-13] All tiff loading goes through this function (called by R2D_LoadImages and LoadOneImage).	// [REPLACED 2026-10-13]
// [NEW 2026-10-13] All tiff loading goes through this function (called by LoadOneImage).
// [NEW 2026-10-13] Returns 1 if the image was loaded, 0 if skipped (image exists and overwrite == 0) or loading failed.
Static Function LoadTIFF(filepath, overwrite)
	string filepath
	variable overwrite
	
	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule
	string header

	// [NEW 2026-10-13] Skip existing image. Checks the current data folder directly, so the image list does not need to be refreshed.
	If(overwrite == 0 && WaveExists($ImageName))
		return 0
	Endif

	// [NEW 2026-10-13] Load the tiff image and its tags in one read. /LTMD stores the tags in :Tag0:T_Tags and works only with /BIGT=1.
	ImageLoad/T=tiff/BIGT=1/Q/O/LTMD/N=$ImageName filepath
	If(V_flag == 0)
		Print "Failed to load: " + filepath
		KillDataFolder/Z :Tag0
		return 0
	Endif

	// Modify image: 32 bit integer to single float. pixels with -1 to NaN.
	wave ImageWave = $ImageName	 // get wave
	Redimension/S ImageWave	 // change data type to single float. 
	Multithread ImageWave[][] = ImageWave[p][q] < 0 ? NaN : ImageWave[p][q] // negative values to NaN; pixels with NaN are automatically masked
	
	// Append tag to the wavenote
	header = "" // initialize header
	wave/T tiftag = :Tag0:T_Tags // get tag
	variable tag_size = DimSize(tiftag,0)
	variable i
	for(i=0; i<tag_size; i++)
		string toWrite	// [NEW 2026-10-13]
		sprintf toWrite, "%s", tiftag[i]	// [NEW 2026-10-13] the tag contains null bytes, which can be removed by sprintf
		toWrite = ReplaceString("\r\n", toWrite, "\r")	// [NEW 2026-10-13] multi-line tags (e.g. IMAGEDESCRIPTION) become separate lines
		toWrite = ReplaceString("\n", toWrite, "")	// [NEW 2026-10-13] remove unecessary newline
		header += toWrite + "\r"
	endfor
	
	Note/K ImageWave, header  // note the wave with the header
	KillDataFolder/Z :Tag0 
	Print fileName

	return 1	// [NEW 2026-10-13] loaded
End


// load edf
// [NEW 2026-10-13] Same structure as LoadTIFF: skip first, one load command, shared helpers. The old version is commented out below.
// Returns 1 if the image was loaded, 0 if skipped (image exists and overwrite == 0).
Static Function LoadEDF(filepath, overwrite)
	string filepath
	variable overwrite

	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule

	// Skip existing image, before opening the file
	If(overwrite == 0 && WaveExists($ImageName))
		return 0
	Endif

	// load header to get the essential information to load the binary data
	variable refNum
	string header = ""
	Open/R refNum as filepath
//	FReadLine/N=4096/T="}" refNum, header	// 512 bits or 4096 bytes is the maximum header length of edf.	// [REPLACED 2026-10-13]
	FReadLine/N=(kEDF_MaxHeaderBytes)/T="}" refNum, header	// [NEW 2026-10-13] maximum header length of edf
	Close refNum
	variable apparent_tag_num = ItemsInList(header)	// get apparent number of tags
	header = RemoveListItem(apparent_tag_num-1, header)	// remove the last apparent tag
	header = ReplaceString("{\n", header, "")	// delete the begining mark of header
	header = ReplaceString("\n", header, "\r") // remove \n and use \r as separator. \r is igor's default
	header = ReplaceString(" ;", header, "") // remove ;

	variable headerSize = NumberByKey("EDF_HeaderSize", header, " = ", "\r") // edf header ends with }\n, but FReadLine /T only recognize 2bytes, "}". So I need to get headerSize from header key.
	variable XSize = NumberByKey("Dim_1", header, " = ", "\r")
	variable YSize = NumberByKey("Dim_2", header, " = ", "\r")

	// Load the edf image as an automatically named wave, then rename it to ImageName
	GBLoadWave/O/B=1/T={2,2}/S=(headerSize)/W=1/A/Q filepath
	wave ImageWave = RenameLoadedWave(StringFromList(0, S_waveNames), ImageName)
	Redimension/N=(XSize,YSize) ImageWave

	FinishImage(ImageWave, header, fileName)	// negative values to NaN, header to wave note, print file name
	return 1
End

// [REPLACED 2026-10-13] old version of LoadEDF
//Static Function LoadEDF(filepath, overwrite)
//	string filepath
//	variable overwrite
//	
//	// set basic information
//	
//	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
//	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule
//	
//	variable refnum
//	string header
//	variable headerSize
//	variable XSize, YSize
//		
//	// load header to get the essential information to load the binary data
//	open/R refNum as filepath
//	header = "" // initialize header
//	FReadLine/N=4096/T="}" refNum, header	// 512 bits or 4096 bytes is the maximum header length of edf.
//	Close refNum	// [NEW 2026-10-13] close the file after reading the header
//	variable apparent_tag_num = ItemsInList(header)	// get apparent number of tags
//	header = RemoveListItem(apparent_tag_num-1, header)	// remove the last apparent tag
//	header = ReplaceString("{\n", header, "")	// delete the begining mark of header
//	header = ReplaceString("\n", header, "\r") // remove \n and use \r as separator. \r is igor's default
//	header = ReplaceString(" ;", header, "") // remove ;
//	
//	headerSize = NumberByKey("EDF_HeaderSize", header, " = ", "\r") // edf header ends with }\n, but FReadLine /T only recognize 2bytes, "}". So I need to get headerSize from header key.
//	XSize = NumberByKey("Dim_1", header, " = ", "\r")
//	YSize = NumberByKey("Dim_2", header, " = ", "\r")
//	
//	// Load the edf image with overwrite flag
//	If(overwrite == 1) // if overwrite is enabled, 
//		GBLoadWave/O/B=1/T={2,2}/S=(headerSize)/W=1/A/Q filepath
//	Elseif(overwrite == 0) // if overwrite is disabled
////		SVAR ImageList = :Red2DPackage:U_ImageList	// [REPLACED 2026-10-13] the image list is not refreshed during recursive loading
////		string resultStr = ListMatch(ImageList, ImageName) // check if the image is new
////		If(strlen(resultStr) == 0)  // if the image is new, load it.
//		If(!WaveExists($ImageName))  // [NEW 2026-10-13] if the image is new, load it. Checks the current data folder directly, same as LoadTIFF.
//			GBLoadWave/B=1/T={2,2}/S=(headerSize)/W=1/A/Q filepath
//		Else	// skip loading and set filename to empty to skip following file adjustment and header loading.
//			fileName =""  
//		Endif
//	Endif
//	
//	// Adjust loaded image
//	If(strlen(filename) > 0)	// if the file is loaded
//		// Modify images
//		string LoadedWaveName = StringFromList(0,S_waveNames)	// GBLoadWave will add a sequential number to the wavename. So I need to use S_waveNames to identify the true wave name.
//		Duplicate/O $LoadedWaveName, $ImageName
//		KillWaves/Z $LoadedWaveName
//		wave ImageWave = $ImageName	 // get wave
//		Redimension/N=(XSize,YSize) ImageWave //
//		Multithread ImageWave[][] = ImageWave[p][q] <= -1 ? NaN : ImageWave[p][q] // negative values to NaN; pixels with NaN are automatically masked
//		
//		// Append tag to the wavenote
//		Note/K ImageWave, header
//		
//		Print fileName
//
//	Endif
//
//	return strlen(fileName) > 0	// [NEW 2026-10-13] 1 if loaded, 0 if skipped (fileName is set to "" when skipped). Used by LoadOneImage.
//End

// load text images, including .txt, .dat, .asc
// [NEW 2026-10-13] Same structure as LoadTIFF: skip first, one load command, shared helpers. The old version is commented out below.
// Returns 1 if the image was loaded, 0 if skipped (image exists and overwrite == 0).
Static Function LoadTEXTImage(filepath, overwrite)
	string filepath
	variable overwrite

	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule

	// Skip existing image
	If(overwrite == 0 && WaveExists($ImageName))
		return 0
	Endif

	// Load the text image as an automatically named wave, then rename it to ImageName
	LoadWave/G/D/O/M/A filepath  // load images
	wave ImageWave = RenameLoadedWave(StringFromList(0, S_waveNames), ImageName)
	Redimension/S ImageWave // change to single float

	// Read the header: lines at the top of the file, until the first empty line
	variable refNum
	string header = ""
	string buffer = ""
	variable j = 0
	Open/R refNum as filepath
	Do
		FReadLine refNum, buffer //Read one line each until find the specified string
		if(strlen(buffer) <= 1)	// 0 does not work for a line with only \r\n. so I set 1 instead.
		// this break statement is desgined for SANS-U dat files. New break statement may be required for the other text images.
			break
		endif
		header += buffer
		j++
	while(j<100)  // 100 is set to avoid loading all lines.
	Close refNum

	FinishImage(ImageWave, header, fileName)	// negative values to NaN, header to wave note, print file name
	return 1
End

// [REPLACED 2026-10-13] old version of LoadTEXTImage
//Static Function LoadTEXTImage(filepath, overwrite)
//	string filepath
//	variable overwrite
//	
//	// set basic information
//	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
//	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule
//	
//	variable refnum
//	string header = ""	// initialize
//	string buffer = "" // initialize
//		
//	// Load the Text image with overwrite flag
//	If(overwrite == 1) // if overwrite is enabled, 
//		LoadWave/G/D/O/M/A filepath  // load images
//	Elseif(overwrite == 0) // if overwrite is disabled
////		SVAR ImageList = :Red2DPackage:U_ImageList	// [REPLACED 2026-10-13] the image list is not refreshed during recursive loading
////		string resultStr = ListMatch(ImageList, ImageName) // check if the image is new
////		If(strlen(resultStr) == 0)  // if the image is new, load it.
//		If(!WaveExists($ImageName))  // [NEW 2026-10-13] if the image is new, load it. Checks the current data folder directly, same as LoadTIFF.
//			LoadWave/G/D/M/A filepath  // load images
//		Else	// skip loading and set filename to empty to skip following file adjustment and header loading.
//			fileName =""  
//		Endif
//	Endif
//	
//	// Adjust loaded image
//	If(strlen(filename) > 0)	// if the file is loaded
//		// Modify images
//		string LoadedWaveName = StringFromList(0,S_waveNames)	// GBLoadWave will add a sequential number to the wavename. So I need to use S_waveNames to identify the true wave name.
//		Duplicate/O $LoadedWaveName, $ImageName
//		KillWaves/Z $LoadedWaveName
//		wave ImageWave = $ImageName	 // get wave
//		Redimension/S ImageWave // change from integer to single float
//		Multithread ImageWave[][] = ImageWave[p][q] <= -1 ? NaN : ImageWave[p][q] // negative values to NaN; pixels with NaN are automatically masked
//		
//		// Append tag to the wavenote
//		Open/R refNum as filepath
//		variable j = 0
//		Do
//			FReadLine refNum, buffer //Read one line each until find the specified string
//			if(strlen(buffer) <= 1)	// 0 does not work for a line with only \r\n. so I set 1 instead.
//			// this break statement is desgined for SANS-U dat files. New break statement may be required for the other text images.
//				break
//			endif
//			header += buffer
//			j++
//		while(j<100)  // 100 is set to avoid loading all lines.
//		Close refNum	// [NEW 2026-10-13] close the file after reading the header
//		Note/K ImageWave, header
//		
//		Print fileName
//
//	Endif
//
//	return strlen(fileName) > 0	// [NEW 2026-10-13] 1 if loaded, 0 if skipped (fileName is set to "" when skipped). Used by LoadOneImage.
//End

// load sans-u mdat binary
// [NEW 2026-10-13] Same structure as LoadTIFF: skip first, one load command, shared helpers. The old version is commented out below.
// Returns 1 if the image was loaded, 0 if skipped (image exists and overwrite == 0).
Static Function Load_SANSU_MainPSD_binary(filepath, overwrite)
	string filepath
	variable overwrite

	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule
//	variable headerSize = 2056	// [REPLACED 2026-10-13]
	variable headerSize = kSANSU_MainHeaderBytes	// [NEW 2026-10-13]

	// Skip existing image
	If(overwrite == 0 && WaveExists($ImageName))
		return 0
	Endif

	// Load the image as an automatically named wave (/A, new), then rename it to ImageName
	// 127*128*4=65024 bytes; 67080-65024=2056
	// 128*128*4=65536 bytes; 67080-65536=1544 bytes. I do not know why but sans-u saving 2d data as 127*128.
	GBLoadWave/O/T={96,2}/S=(headerSize)/W=1/A filepath  // load images
	wave ImageWave = RenameLoadedWave(StringFromList(0, S_waveNames), ImageName)
//	Redimension/N=(128,127) ImageWave // 127 rows and 128 columns in .dat file. .mdat file seems transposed.	// [REPLACED 2026-10-13]
	Redimension/N=(kSANSU_MainRows,kSANSU_MainCols) ImageWave // [NEW 2026-10-13] 127 rows and 128 columns in .dat file. .mdat file seems transposed.
	MatrixOP/O/FREE outWave = ImageWave^t	// transpose the image
	Duplicate/O outWave ImageWave

	// Read the header
	variable refNum
	string header = ""
	Open/R refNum as filepath
	FReadLine/N=(headerSize) refNum, header
	Close refNum

	FinishImage(ImageWave, header, fileName)	// negative values to NaN, header to wave note, print file name
	return 1
End

// [REPLACED 2026-10-13] old version of Load_SANSU_MainPSD_binary
//Static Function Load_SANSU_MainPSD_binary(filepath, overwrite)
//	string filepath
//	variable overwrite
//	
//	// set basic information
//	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
//	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule
//	
//	variable refnum
//	string header = ""	// initialize
//	string buffer = "" // initialize
//	variable headerSize = 2056
//		
//	// Load the Text image with overwrite flag
//	If(overwrite == 1) // if overwrite is enabled, 
//		GBLoadWave/O/T={96,2}/S=(headerSize)/W=1 filepath  // load images 127*128*4=65024 bytes; 67080-65024=2056
//		// 128*128*4=65536 bytes; 67080-65536=1544 bytes. I do not know why but sans-u saving 2d data as 127*128.
//	Elseif(overwrite == 0) // if overwrite is disabled
////		SVAR ImageList = :Red2DPackage:U_ImageList	// [REPLACED 2026-10-13] the image list is not refreshed during recursive loading
////		string resultStr = ListMatch(ImageList, ImageName) // check if the image is new
////		If(strlen(resultStr) == 0)  // if the image is new, load it.
//		If(!WaveExists($ImageName))  // [NEW 2026-10-13] if the image is new, load it. Checks the current data folder directly, same as LoadTIFF.
//			GBLoadWave/T={96,2}/S=(headerSize)/W=1 filepath  // load images
//		Else	// skip loading and set filename to empty to skip following file adjustment and header loading.
//			fileName =""  
//		Endif
//	Endif
//	
//	// Adjust loaded image
//	If(strlen(filename) > 0)	// if the file is loaded
//		// Modify images
//		string LoadedWaveName = StringFromList(0,S_waveNames)	// GBLoadWave will add a sequential number to the wavename. So I need to use S_waveNames to identify the true wave name.
//		Duplicate/O $LoadedWaveName, $ImageName
//		KillWaves/Z $LoadedWaveName
//		wave ImageWave = $ImageName	 // get wave
//		Redimension/N=(128,127) ImageWave // 127 rows and 128 columns in .dat file. .mdat file seems transposed.
//		MatrixOP/O/FREE outWave = ImageWave^t	// transpose the image
//		Duplicate/O outWave ImageWave
//		Multithread ImageWave[][] = ImageWave[p][q] <= -1 ? NaN : ImageWave[p][q] // negative values to NaN; pixels with NaN are automatically masked
//		
//		// Append tag to the wavenote
//		Open/R refNum as filepath
//		header = "" // initialize header
//		FReadLine/N=(headerSize) refNum, header
//		Close refNum	// [NEW 2026-10-13] close the file after reading the header
//
//		Note/K ImageWave, header
//		
//		Print fileName
//
//	Endif
//
//	return strlen(fileName) > 0	// [NEW 2026-10-13] 1 if loaded, 0 if skipped (fileName is set to "" when skipped). Used by LoadOneImage.
//End

// load sans-u sdat binary
// [NEW 2026-10-13] Same structure as LoadTIFF: skip first, one load command, shared helpers. The old version is commented out below.
// Returns 1 if the image was loaded, 0 if skipped (image exists and overwrite == 0).
Static Function Load_SANSU_PMT_binary(filepath, overwrite)
	string filepath
	variable overwrite

	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule
//	variable headerSize = 2060	// [REPLACED 2026-10-13]
	variable headerSize = kSANSU_PMTHeaderBytes	// [NEW 2026-10-13]

	// Skip existing image
	If(overwrite == 0 && WaveExists($ImageName))
		return 0
	Endif

	// Load the image as an automatically named wave (/A, new), then rename it to ImageName
	GBLoadWave/O/T={96,2}/S=(headerSize)/W=1/A filepath  // load images
	wave ImageWave = RenameLoadedWave(StringFromList(0, S_waveNames), ImageName)
//	Redimension/N=(256,256) ImageWave	// [REPLACED 2026-10-13]
	Redimension/N=(kSANSU_PMTSize,kSANSU_PMTSize) ImageWave	// [NEW 2026-10-13]

	// Read the header and put each item on its own line
	variable refNum
	string header = ""
	Open/R refNum as filepath
	FReadLine/N=(headerSize) refNum, header
	Close refNum
	header = ReplaceString("      ", header, "\r")
	header = ReplaceString("     ", header, "\r")
	header = ReplaceString("    ", header, "\r")
	header = ReplaceString("   ", header, "\r")
	header = ReplaceString("  ", header, "\r")
	header = RemoveFromList("",header,"\r")

	FinishImage(ImageWave, header, fileName)	// negative values to NaN, header to wave note, print file name
	return 1
End

// [REPLACED 2026-10-13] old version of Load_SANSU_PMT_binary
//Static Function Load_SANSU_PMT_binary(filepath, overwrite)
//	string filepath
//	variable overwrite
//	
//	// set basic information
//	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
//	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule
//	
//	variable refnum
//	string header = ""	// initialize
//	string buffer = "" // initialize
//	variable headerSize = 2060
//		
//	// Load the Text image with overwrite flag
//	If(overwrite == 1) // if overwrite is enabled, 
//		GBLoadWave/O/T={96,2}/S=(headerSize)/W=1 filepath  // load images
//	Elseif(overwrite == 0) // if overwrite is disabled
////		SVAR ImageList = :Red2DPackage:U_ImageList	// [REPLACED 2026-10-13] the image list is not refreshed during recursive loading
////		string resultStr = ListMatch(ImageList, ImageName) // check if the image is new
////		If(strlen(resultStr) == 0)  // if the image is new, load it.
//		If(!WaveExists($ImageName))  // [NEW 2026-10-13] if the image is new, load it. Checks the current data folder directly, same as LoadTIFF.
//			GBLoadWave/T={96,2}/S=(headerSize)/W=1 filepath  // load images
//		Else	// skip loading and set filename to empty to skip following file adjustment and header loading.
//			fileName =""  
//		Endif
//	Endif
//	
//	// Adjust loaded image
//	If(strlen(filename) > 0)	// if the file is loaded
//		// Modify images
//		string LoadedWaveName = StringFromList(0,S_waveNames)	// GBLoadWave will add a sequential number to the wavename. So I need to use S_waveNames to identify the true wave name.
//		Duplicate/O $LoadedWaveName, $ImageName
//		KillWaves/Z $LoadedWaveName
//		wave ImageWave = $ImageName	 // get wave
//		Redimension/N=(256,256) ImageWave
//		Multithread ImageWave[][] = ImageWave[p][q] <= -1 ? NaN : ImageWave[p][q] // negative values to NaN; pixels with NaN are automatically masked
//		
//		// Append tag to the wavenote
//		Open/R refNum as filepath
//		header = "" // initialize header
//		FReadLine/N=(headerSize) refNum, header
//		Close refNum	// [NEW 2026-10-13] close the file after reading the header
//		header = ReplaceString("      ", header, "\r")
//		header = ReplaceString("     ", header, "\r")
//		header = ReplaceString("    ", header, "\r")
//		header = ReplaceString("   ", header, "\r")
//		header = ReplaceString("  ", header, "\r")
//		header = RemoveFromList("",header,"\r")
//	
//		Note/K ImageWave, header
//		
//		Print fileName
//
//	Endif
//
//	return strlen(fileName) > 0	// [NEW 2026-10-13] 1 if loaded, 0 if skipped (fileName is set to "" when skipped). Used by LoadOneImage.
//End


// *** Load recursively

// [NEW 2026-10-13] Renamed from ImageLoadSubFolders (it now also loads a single folder). The old version is commented out below.
// Load all images with "extension" in one folder, and also in all its subfolders if recurse = 1.
// Each file is loaded with LoadOneImage. Returns the number of loaded images.
// Based on a script from the Igor forum.
Static Function LoadImagesInFolder(pathName, extension, recurse, level, overwrite, add)
	string pathName	// name of the Igor symbolic path of the folder (created with NewPath)
	string extension	// file name extension, e.g. ".tif"
	variable recurse	// 1: also load all subfolders, 0: this folder only
	variable level	// recursion level. Pass 0. Used to give each level its own temporary symbolic path.
	variable overwrite	// 1: overwrite existing images, 0: skip them
	variable add	// 1: sum the images of each folder into one image, 0: keep each image

	variable folderIndex, fileIndex
	variable numLoaded = 0	// number of images loaded in this folder and its subfolders. Returned.

	string folderPath
	PathInfo $pathName	// Sets S_path
	folderPath = S_path	// full path of this folder

	// Load each file in this folder
	fileIndex = 0
	variable numAdded = 0	// number of images added in this folder (add mode). Used instead of fileIndex, which also counts files that failed to load.
	do
		string fileName
		string refname
		string LoadedWaveList
		Wave/Z Added
		fileName = IndexedFile($pathName, fileIndex, extension)	// return index-th filename in the specified folder
		if (strlen(fileName) == 0)	// no more files
			break
		endif

		string ImageName = R2D_CleanupName(fileName)	// Remove extension and unnecessary characters
		variable loaded
		loaded = LoadOneImage(folderPath + fileName, extension, overwrite)	// uses the loader for this extension. Returns 1 if loaded.
		numLoaded += loaded

		If(loaded)	// if the image was loaded
			// Add waves from the same subfolder.
			If(add == 1)
				If(numAdded == 0)	// make the first loaded wave as the reference wave to add
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
				numAdded += 1
			Endif
		Endif

		fileIndex += 1
	while(1)

	// Add mode: save the summed image of this folder (moved here from the loop exit)
	if(add == 1 && numAdded > 0)
		// Sort wave names and get the first name in alphabet order.
		refname = StringFromList(0, SortList(LoadedWaveList))

		// Check if the files are created by SAXSpoint2.0 (Anton Paar) auto-experiments
		// You can add other special rules here to remove unnecessary characters.
		string str1 = refname[strlen(refname)-14,strlen(refname)-9]
		if(Cmpstr(str1,"_Frame", 1) == 0)
			refname = refname[0, strlen(refname)-15]
		endif

		Duplicate/O/D Added, $refname	// save the combined wave as refname
		KillWaves/Z Added	// delete the original combined wave
		Print num2Str(numAdded) + " files were added and saved as " + refname
	endif

	// Load each subfolder, if recurse = 1
	if (recurse)
		folderIndex = 0
		do
			string subFolderPath
			subFolderPath = IndexedDir($pathName, folderIndex, 1)	// full path of the folderIndex-th subfolder
			if (strlen(subFolderPath) == 0)
				break	// No more folders
			endif

			string subFolderPathName = "R2D_tempFolderPath_" + num2istr(level+1)	// each recursion level has its own temporary symbolic path
			NewPath/Q/O $subFolderPathName, subFolderPath
			numLoaded += LoadImagesInFolder(subFolderPathName, extension, recurse, level+1, overwrite, add)
			KillPath/Z $subFolderPathName

			folderIndex += 1
		while(1)
	endif

	return numLoaded
End

// [REPLACED 2026-10-13] old version of LoadImagesInFolder (was ImageLoadSubFolders)
//// A script from Igor forum. I have modified some parts.
////  ImageLoadSubFolders(pathName, extension, recurse, level)
////  Shows how to recursively find all files in a folder and subfolders.
////  pathName is the name of an Igor symbolic path that you created using NewPath or the Misc->New Path menu item.
////  extension is a file name extension like ".txt" or "????" for all files.
////  recurse is 1 to recurse or 0 to list just the top-level folder.
////  level is the recursion level - pass 0 when calling PrintFoldersAndFiles.
//Static Function ImageLoadSubFolders(pathName, extension, recurse, level, overwrite, add)
//    string pathName     // Name of symbolic path in which to look for folders and files.
//    string extension            // File name extension (e.g., ".txt") or "????" for all files.
//    variable recurse        // True to recurse (do it for subfolders too).
//    variable level          // Recursion level. Pass 0 for the top level.
//    variable overwrite  // Overwrite existing files. 1 for ture (overwrite), 0 for false.
//    variable add 			// Add files (1) or not (0)
//    
//    variable folderIndex, fileIndex
//    
//    string folderPath
//    PathInfo $pathName              // Sets S_path
//    folderPath = S_path
//    
//    fileIndex = 0
//    variable numAdded = 0	// [NEW 2026-10-13] number of images added in this folder. Used instead of fileIndex, which also counts files that failed to load.
//    do
//        string fileName
//        string refname
//        string LoadedWaveList
//        Wave/Z Added
//        fileName = IndexedFile($pathName, fileIndex, extension)  // return index-th filename in the specified folder
//        
//        /// Loop exit statemement
//		if (strlen(fileName) == 0) // if no more file exists, get out the do-while-loop.
//
//			//////////////////////////
//			///A block for adding images///
//			if(add == 1 && numAdded > 0)  // [NEW 2026-10-13] change names of the added waves, only if at least one image was added.
//				// Sort wave names and get the first name in alphabet order.
//				refname = StringFromList(0, SortList(LoadedWaveList))
//        			
//				// Check if the files are created by SAXSpoint2.0 (Anton Paar) auto-experiments
//				// You can add other special rules here to remove unnecessary characters.
//				string str1 = refname[strlen(refname)-14,strlen(refname)-9]
//				if(Cmpstr(str1,"_Frame", 1) == 0)
//					refname = refname[0, strlen(refname)-15]
//				endif
//
//				Duplicate/O/D Added, $refname  // save the combined wave as refname
//				KillWaves/Z Added  // delete the original combined wave
//				Print num2Str(numAdded) + " files were added and saved as " + refname	// [NEW 2026-10-13]
//   	  		endif
//			////////////////////////
//        		
//        break
//		endif
//
//		/// Load images
//		string ImageName = R2D_CleanupName(fileName) // Remove extension and unnecessary characters
//		variable loaded  // [NEW 2026-10-13]
////		loaded = LoadTIFF(folderPath + fileName, overwrite)  // [NEW 2026-10-13] path is the full path of this folder (from PathInfo above). Returns 1 if loaded.	// [REPLACED 2026-10-13]
//		loaded = LoadOneImage(folderPath + fileName, extension, overwrite)  // [NEW 2026-10-13] uses the loader for this extension. folderPath is the full path of this folder. Returns 1 if loaded.
//
//		If(loaded)  // [NEW 2026-10-13] if the image was loaded
//			// Add waves from the same subfolder.
//			If(add == 1)
//				If(numAdded == 0)	// [NEW 2026-10-13] make the first loaded wave as the reference wave to add
//					Duplicate/O/D $ImageName, Added
//					LoadedWaveList = ""
//					LoadedWaveList = AddListItem(ImageName, LoadedWaveList)
//					Killwaves/Z $ImageName				
//				Else
//					Wave Toadd = $ImageName
//					MultiThread Added += Toadd
//					KillWaves/Z Toadd
//					LoadedWaveList = AddListItem(ImageName, LoadedWaveList)
//				Endif
//				numAdded += 1	// [NEW 2026-10-13]
//			Endif
//		Endif
//			
//        fileIndex += 1
//    while(1)
//
//    
//	if (recurse)                                   // Do we want to go into subfolder?
//		folderIndex = 0
//		do
//			string subFolderPath
//			subFolderPath = IndexedDir($pathName, folderIndex, 1)	// (NameOfParentSymbolicPath, index of subfolder, bitwise parameter:0, i.e.1 = full path)
//			if (strlen(subFolderPath) == 0)
//			    break                           // No more folders
//			endif
//			
//			string subFolderPathName = "tempPrintFoldersPath_" + num2istr(level+1)
//			
//			// Now we get the path to the new parent folder
//			
//			NewPath/Q/O $subFolderPathName, subFolderPath
//			ImageLoadSubFolders(subFolderPathName, extension, recurse, level+1, overwrite, add)
//			KillPath/Z $subFolderPathName
//			
//			folderIndex += 1
//		while(1)	// This would loop forever until "break" actives.
//	endif
//    
//End


// *** Organize Images to folders by their name
// [REPLACED 2026-10-13] moved to misc/R2D_misc_2D.ipf. Commented out here so the function is not defined twice.
//Function R2D_SortImagesByBeamSizeAndSDD()
//	
//	R2D_CreateImageList(1)	// create an imagelist
//	wave/T imagelist = :Red2Dpackage:imagelist
//	variable numOfImages = DimSize(imagelist, 0)
//	
//	variable i
//	string datafoldername
//	string SDD, BeamSize
//	string wname
//	For(i=0; i<numOfImages; i++)
//		wname = imagelist[i]
//		Wave target = $wname
//		BeamSize = StringFromList(0, wname, "_") + StringFromList(1, wname, "_")
//		SDD = StringFromList(5, wname, "_")
//		datafoldername = "BeamSize"+BeamSize+"_SDD"+SDD
//		NewDataFolder/O $datafoldername
//		MoveWave target, $(":"+datafoldername+":")
//	Endfor
//	
//End

// *** LOAD IMAGES IN ALL SUBFOLDERS and add images within the same subfolders
Function R2D_LoadAllTIFF_addSubfolders()
	
	NewPath/O R2D_PCImageFolder
	If(V_flag == 0)
		Print "Loading images..."
//		ImageLoadSubFolders("R2D_PCImageFolder", ".tif", 1, 0, 1, 1)  // add files	// [REPLACED 2026-10-13] renamed
		LoadImagesInFolder("R2D_PCImageFolder", ".tif", 1, 0, 1, 1)	// [NEW 2026-10-13] add files. arguments: (path, extension, recurse, level, overwrite, add)
		Print "Completed"
	Else
		Print "User canceled"
		Abort
	Endif
	
	R2D_CreateImageList(2) // create an imagelist with the order date created
	
	PathInfo/S R2D_PCImageFolder  // set default path to main folder.

End