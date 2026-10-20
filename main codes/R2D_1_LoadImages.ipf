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
	string mode			// "folder", "files", "recursive", "recursive_df" 2026-10-13
						// [NEW 2026-10-13] "recursive_df": same as "recursive", but each subfolder is loaded into a data folder with the same name.
						// Images in the selected folder are loaded into the current data folder. Nested subfolders become nested data folders.
	variable overwrite	// 0 false, 1 true
	string folderPath	// ":" separated path to the folder. if provided, do not show a dialog.
	
	// prepare common strings and variables
	string filePaths = ""	// initialize file path list
	variable numLoaded = 0	// [NEW 2026-10-13] number of loaded images, for the message at the end

	// [NEW 2026-10-13] Check the extension once, before showing any dialog. GetFileFilter returns "" for unsupported extensions.
	string fileFilters = GetFileFilter(extension)
	if(strlen(fileFilters) == 0)
		Print "Unsupported extension: " + extension
		return filePaths
	endif

	// [NEW 2026-10-13] moved here from the "folder" branch below, and added toDataFolders
	variable toDataFolders = (cmpstr(mode, "recursive_df") == 0)	// [NEW 2026-10-13] 1: load each subfolder into its own data folder
	variable recurse = (cmpstr(mode, "recursive") == 0 || toDataFolders)	// [NEW 2026-10-13] 0: only the selected folder ("folder"), 1: also all subfolders ("recursive", "recursive_df")

	// Get file path list.	The codes differs based on "mode", "extension", and "folderPath".
	if(cmpstr(mode, "folder") == 0 || recurse)	// [NEW 2026-10-13] "folder" and "recursive" modes share this code. Both use LoadImagesInFolder.
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

		numLoaded = LoadImagesInFolder("R2D_PCImageFolder", extension, recurse, 0, overwrite, 0, toDataFolders)	// [NEW 2026-10-13] arguments: (path, extension, recurse, level, overwrite, add, toDataFolders)

		PathInfo/S R2D_PCImageFolder  // set default symbolic path to main folder.

	elseif(cmpstr(mode, "files") == 0)	//"files" mode
		variable refNum

		// open a dialog and let user select the files, then get a list of selected files
		Open/D/R/MULT=1/F=fileFilters/M="Select one or more files" refNum // refNum is not used when /D exists but need to be supplied here.
		filePaths = ReplaceString("\r", S_fileName, ";")	//S_filename stores the selected files names separated by "\r"

		// if no files is selected, close this proceddure.
		if (strlen(filePaths) == 0)
			Print "User cancelled"
			return filePaths		// Will be empty if user canceled
		endif

		// Load each selected file.
		string filepath
		variable numFilesSelected = ItemsInList(filePaths)
		variable i
		for(i=0; i<numFilesSelected; i+=1)	// one loop for every extension. LoadOneImage picks the loader.
			filepath = StringFromList(i, filePaths) // Get the path of ith of selected waves.
			numLoaded += LoadOneImage(filepath, extension, overwrite)	// [NEW 2026-10-13] count loaded images
		endfor
			
	else
	
		print "Something wrong in the mode selection. Please check the codes."
		return filePaths
		
	endif
	
	If(overwrite)	// [NEW 2026-10-13]
		Print num2str(numLoaded) + " images were loaded. Existing images were overwritten."
	Else
		Print num2str(numLoaded) + " new images were loaded. Existing images were skipped."
	Endif

//	R2D_CreateImageList(1) // create an imagelist with the name order [2026-10-20] We may no longer need this.

	return filePaths	// [NEW 2026-10-13] selected file paths in "files" mode, empty in "folder" and "recursive" modes
End

// *** Misc
// [NEW 2026-10-13] Load one image with the loader for its extension. Used by all modes: LoadImagesInFolder ("folder", "recursive") and R2D_LoadImages ("files").
// Each extension has its own loader below. To support a new extension, write a loader and add a case here.
// Returns 1 if the image was loaded, 0 if skipped, loading failed, or the extension is not supported.
Static Function LoadOneImage(filepath, extension, overwrite)
	string filepath
	string extension
	variable overwrite

	strswitch(extension)
		case ".tif":
			return LoadTIFF(filepath, overwrite)
		case ".edf":
			return LoadEDF(filepath, overwrite)
		case ".h5z":
			return R2D_Load_SAXSpoint_h5z(filepath)
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
		case ".h5z":	// xenocs
			return "Data Files (*.h5z):.h5z;"
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

// [NEW 2026-10-13] Shared last steps of all the loaders.
// Negative values to NaN, header to the wave note, print the file name.
Static Function FinishImage(ImageWave, header, fileName)
	wave ImageWave
	string header
	string fileName

	Multithread ImageWave[][] = ImageWave[p][q] <= -1 ? NaN : ImageWave[p][q] // negative values to NaN; pixels with NaN are automatically masked
	Note/K ImageWave, header	// note the wave with the header
	Print fileName
End

// *** Load one image
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

	// Modify image: 32 bit integer to single float. Pixels with -1 become NaN in FinishImage below.
	wave ImageWave = $ImageName	 // get wave
	Redimension/S ImageWave	 // change data type to single float.

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
	
	KillDataFolder/Z :Tag0
	FinishImage(ImageWave, header, fileName)	// [NEW 2026-10-13] negative values to NaN, header to wave note, print file name
	return 1	// [NEW 2026-10-13] loaded
End


// [NEW 2026-10-13] Same structure as LoadTIFF: skip first, one load command, shared helpers. The old version is commented out below.
// Returns 1 if the image was loaded, 0 if skipped (image exists and overwrite == 0) or loading failed.
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

	// Load the edf image as an automatically named wave, then rename it to ImageName. GBLoadWave adds a sequential number after name. So I need rename it.
	GBLoadWave/O/B=1/T={2,2}/S=(headerSize)/W=1/A/Q filepath
	If(V_flag == 0)	// [NEW 2026-10-13] V_flag is the number of loaded waves. Skip the file if nothing was loaded, same as LoadTIFF.
		Print "Failed to load: " + filepath
		return 0
	Endif
	wave ImageWave = RenameLoadedWave(StringFromList(0, S_waveNames), ImageName)
	Redimension/N=(XSize,YSize) ImageWave

	FinishImage(ImageWave, header, fileName)	// negative values to NaN, header to wave note, print file name
	return 1
End

// load text images, including .txt, .dat, .asc
// [NEW 2026-10-13] Same structure as LoadTIFF: skip first, one load command, shared helpers. The old version is commented out below.
// Returns 1 if the image was loaded, 0 if skipped (image exists and overwrite == 0) or loading failed.
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
	If(V_flag == 0)	// [NEW 2026-10-13] V_flag is the number of loaded waves. Skip the file if nothing was loaded, same as LoadTIFF.
		Print "Failed to load: " + filepath
		return 0
	Endif
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

// load sans-u mdat binary
// [NEW 2026-10-13] Same structure as LoadTIFF: skip first, one load command, shared helpers. The old version is commented out below.
// Returns 1 if the image was loaded, 0 if skipped (image exists and overwrite == 0) or loading failed.
Static Function Load_SANSU_MainPSD_binary(filepath, overwrite)
	string filepath
	variable overwrite

	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule
	variable headerSize = kSANSU_MainHeaderBytes	// [NEW 2026-10-13]

	// Skip existing image
	If(overwrite == 0 && WaveExists($ImageName))
		return 0
	Endif

	// Load the image as an automatically named wave (/A, new), then rename it to ImageName
	// 127*128*4=65024 bytes; 67080-65024=2056
	// 128*128*4=65536 bytes; 67080-65536=1544 bytes. I do not know why but sans-u saving 2d data as 127*128.
	GBLoadWave/O/T={96,2}/S=(headerSize)/W=1/A filepath  // load images
	If(V_flag == 0)	// [NEW 2026-10-13] V_flag is the number of loaded waves. Skip the file if nothing was loaded, same as LoadTIFF.
		Print "Failed to load: " + filepath
		return 0
	Endif
	wave ImageWave = RenameLoadedWave(StringFromList(0, S_waveNames), ImageName)
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

// load sans-u sdat binary
// [NEW 2026-10-13] Same structure as LoadTIFF: skip first, one load command, shared helpers. The old version is commented out below.
// Returns 1 if the image was loaded, 0 if skipped (image exists and overwrite == 0) or loading failed.
Static Function Load_SANSU_PMT_binary(filepath, overwrite)
	string filepath
	variable overwrite

	string filename = parseFilePath(0, filepath, ":", 1, 0) //Get file name string
	string ImageName = R2D_CleanupName(fileName)	// cleanup image name to fit the igor rule
	variable headerSize = kSANSU_PMTHeaderBytes	// [NEW 2026-10-13]

	// Skip existing image
	If(overwrite == 0 && WaveExists($ImageName))
		return 0
	Endif

	// Load the image as an automatically named wave (/A, new), then rename it to ImageName
	GBLoadWave/O/T={96,2}/S=(headerSize)/W=1/A filepath  // load images
	If(V_flag == 0)	// [NEW 2026-10-13] V_flag is the number of loaded waves. Skip the file if nothing was loaded, same as LoadTIFF.
		Print "Failed to load: " + filepath
		return 0
	Endif
	wave ImageWave = RenameLoadedWave(StringFromList(0, S_waveNames), ImageName)
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

// *** Load recursively
// [NEW 2026-10-13] Renamed from ImageLoadSubFolders (it now also loads a single folder). The old version is commented out below.
// Load all images with "extension" in one folder, and also in all its subfolders if recurse = 1.
// Each file is loaded with LoadOneImage. Returns the number of loaded images.
// Based on a script from the Igor forum.
Static Function LoadImagesInFolder(pathName, extension, recurse, level, overwrite, add, toDataFolders)
	string pathName	// name of the Igor symbolic path of the folder (created with NewPath)
	string extension	// file name extension, e.g. ".tif"
	variable recurse	// 1: also load all subfolders, 0: this folder only
	variable level	// recursion level. Pass 0. Used to give each level its own temporary symbolic path.
	variable overwrite	// 1: overwrite existing images, 0: skip them
	variable add	// 1: sum the images of each folder into one image, 0: keep each image
	variable toDataFolders	// [NEW 2026-10-13] 1: load each subfolder into a data folder with the same name, 0: load everything into the current data folder

	variable folderIndex, fileIndex
	variable numLoaded = 0	// number of images loaded in this folder and its subfolders. Returned.

	string folderPath
	PathInfo $pathName	// Sets S_path
	folderPath = S_path	// full path of this folder

	// Load each file in this folder
	// [NEW 2026-10-14] Load in name order. 16: case-insensitive, and numbers in names are sorted by value, e.g. "img9" comes before "img10".
	string fileList = SortList(IndexedFile($pathName, -1, extension), ";", 16)	// -1: list of all files with "extension" in this folder
	fileIndex = 0
	variable numAdded = 0	// number of images added in this folder (add mode). Used instead of fileIndex, which also counts files that failed to load.
	do
		string fileName
		string refname
		string LoadedWaveList
		Wave/Z Added
		fileName = StringFromList(fileIndex, fileList)	// [NEW 2026-10-14] index-th filename in name order. Was IndexedFile($pathName, fileIndex, extension), which uses the order of the file system.
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

	// [NEW 2026-10-13] Image list of each data folder made by toDataFolders. The image list of the top data folder is made by R2D_LoadImages.
	if(toDataFolders && level > 0 && numLoaded > 0)	// numLoaded counts only this folder here, the subfolders are loaded below
		R2D_CreateImageList(1)	// 1: name order
	endif

	// Load each subfolder, if recurse = 1
	if (recurse)
		// [NEW 2026-10-14] Load subfolders in name order, same as the files above.
		string folderList = SortList(IndexedDir($pathName, -1, 0), ";", 16)	// -1: list of all subfolder names (not full paths) in this folder
		folderIndex = 0
		do
			string subFolderName, subFolderPath
			subFolderName = StringFromList(folderIndex, folderList)	// [NEW 2026-10-14] folderIndex-th subfolder name in name order. Was IndexedDir($pathName, folderIndex, 1), which uses the order of the file system.
			if (strlen(subFolderName) == 0)
				break	// No more folders
			endif
			subFolderPath = folderPath + subFolderName	// full path of the subfolder. folderPath ends with ":".

			string subFolderPathName = "R2D_tempFolderPath_" + num2istr(level+1)	// each recursion level has its own temporary symbolic path
			NewPath/Q/O $subFolderPathName, subFolderPath

			// [NEW 2026-10-13] toDataFolders: move into a data folder with the subfolder name. It is created in the current data folder, so nested subfolders become nested data folders.
			DFREF parentDFR = GetDataFolderDFR()
			if(toDataFolders)
				string dfName = CleanupName(subFolderName, 0)	// subfolder name with strict name rules, same as the image names, e.g. "2026-10-13" -> "X2026_10_13"
				NewDataFolder/O/S $dfName
			endif
			DFREF subDFR = GetDataFolderDFR()

			numLoaded += LoadImagesInFolder(subFolderPathName, extension, recurse, level+1, overwrite, add, toDataFolders)
			KillPath/Z $subFolderPathName

			// [NEW 2026-10-13] go back to the parent data folder. Remove the new data folder if nothing was loaded in it or its subfolders.
			if(toDataFolders)
				SetDataFolder parentDFR
				if(CountObjectsDFR(subDFR, 1) + CountObjectsDFR(subDFR, 2) + CountObjectsDFR(subDFR, 3) + CountObjectsDFR(subDFR, 4) == 0)	// no waves, variables, strings, or data folders
					KillDataFolder/Z subDFR
				endif
			endif

			folderIndex += 1
		while(1)
	endif


	return numLoaded
End

// *** Load and add images in each subfolder recursively
Function R2D_LoadAndAdd_subfolders_recursive(extension)
	string extension
	
	NewPath/O R2D_PCImageFolder
	If(V_flag == 0)
		Print "Loading images..."
		LoadImagesInFolder("R2D_PCImageFolder", extension, 1, 0, 1, 1, 0)	// [NEW 2026-10-13] add files. arguments: (path, extension, recurse, level, overwrite, add, toDataFolders)
		Print "Completed"
	Else
		Print "User canceled"
		Abort
	Endif
	
	R2D_CreateImageList(2) // create an imagelist with the order date created
	
	PathInfo/S R2D_PCImageFolder  // set default path to main folder.

End

// *** Organize Images to folders by their name
Function R2D_SortImagesByBeamSizeAndSDD()
	
	R2D_CreateImageList(1)	// create an imagelist
	wave/T imagelist = :Red2Dpackage:imagelist
	variable numOfImages = DimSize(imagelist, 0)
	
	variable i
	string datafoldername
	string SDD, BeamSize
	string wname
	For(i=0; i<numOfImages; i++)
		wname = imagelist[i]
		Wave target = $wname
		BeamSize = StringFromList(0, wname, "_") + StringFromList(1, wname, "_")
		SDD = StringFromList(5, wname, "_")
		datafoldername = "BeamSize"+BeamSize+"_SDD"+SDD
		NewDataFolder/O $datafoldername
		MoveWave target, $(":"+datafoldername+":")
	Endfor
	
End