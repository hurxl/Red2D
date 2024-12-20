﻿#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// *************************
// Get 1D wave list with a filter
// *************************

Function/S R2D_WaveList_nofits(matchStr)
	string matchStr

	String List = WaveList(matchStr, ";","DIMS:1,TEXT:0") //return a list of int in current datafolder
	List = R2D_skip_fit(List)
	List = SortList(List, ";", 16)

	return List

End

// *************************
// Skip the fit waves, mostly used in display and normalize waves.
// *************************

Function/S R2D_skip_fit(TempList)
	String TempList
	
	String ItemsToBeDeleted
	Do
		ItemsToBeDeleted = ListMatch(TempList, "fit_*")
		TempList = RemoveFromList(ItemsToBeDeleted, TempList)
	While(strlen(ItemsToBeDeleted) != 0)
	Do
		ItemsToBeDeleted = ListMatch(TempList, "fitX_*")
		TempList = RemoveFromList(ItemsToBeDeleted, TempList)
	While(strlen(ItemsToBeDeleted) != 0)
	
	Return TempList
End


// *************************
// Check unexpected operations, used throughout the R2D package.
// *************************

// Check if the Images exist in the selected folder, and if their sizes are the same.
// If not warn the user and stop this procedure.
Function R2D_Error_ImagesExist([NoMessage])
	Variable NoMessage  // if specified (any value), suppress the error message.
	
	// Check if there are 2D waves. Note that igor cannot know if it is a image or other two 2D waves.
	String refImageList = Wavelist("*",";","DIMS:2,TEXT:0")
	Variable numOf2D = itemsInList(refImageList)
	If(numOf2D == 0)
		If(ParamIsDefault(NoMessage))  // if not specified
			DoAlert 0, "No 2D images in current datafolder. Please select a datafolder where the images exist and set the folder as current datafolder."
			Print "Error message:"
			Print "No 2D images in current datafolder."
			Print "Please select a datafolder where the images exist and set the folder as current datafolder."
		Endif
		return -1
	Endif
	
	// Check if the DimSize of 2D images are the same.
	Wave ref2D0 = $StringFromList(0, refImageList)
	Variable DimX0 = DimSize(ref2D0, 0)
	Variable DimY0 = DimSize(ref2D0, 1)
	Variable i
	For(i=1; i<numOf2D; i++)
		Wave ref2D = $StringFromList(i, refImageList)
		If(DimSize(ref2D, 0) != DimX0 || DimSize(ref2D, 1) != DimY0)
			If(ParamIsDefault(NoMessage) == 1)
				DoAlert 0, "The size of images must be the consistent in this datafolder. Please delete 2D waves with different sizes."
				Print "Error message:"
				Print "The size of images must be the consistent in this datafolder. Please delete 2D waves with different sizes."
			Endif
			return -1
//		Elseif(DimSize(ref2D, 1) != DimY0)
//			If(ParamIsDefault(NoMessage) == 1)
//				DoAlert 0, "The size of images must be the consistent in this datafolder."
//				Print "Error message:"
//				Print "Remove the images with different size."
//			Endif
//			return -1
		Endif
	Endfor
		
	return 0
End


// Check if in 1D datafolder: *_i exist?
Function R2D_Error_1Dexist([NoMessage])
	Variable NoMessage

	String IntList = WaveList("*_i", ";","DIMS:1,TEXT:0") //return a list of int in current datafolder
	Variable numOfInt = Itemsinlist(IntList)

	If(numOfInt <= 0)
		If(ParamIsDefault(NoMessage) == 1)
			DoAlert 0, "No 1D intensity waves exists in current datafolder. Please move to a datafolder containing 1D intensity waves."
			Print "Error message:"
			Print "No 1D intensity waves exists in current datafolder. Please move to a datafolder containing 1D intensity waves."
		Endif
//			Print "Success"
			Return -1  // -1 for error.
	Endif
		
	Return 0	// 0 for ok

End

// Check if datasheet exist for 1D folder only
Function R2D_Error_DatasheetExist1D()
	
	wave/Z/T Datasheet = ::Red2DPackage:Datasheet
	variable numOfImages = DimSize(Datasheet,0)
	If(WaveExists(Datasheet) == 0)
		DoAlert 0, "No datasheet exists in the Red2DPackage folder."
		Print "Error message:"
		Print "No datasheet exists in the Red2DPackage folder."
		Return -1	
	Endif
	
	If(numOfImages == 0)
		DoAlert 0, "The datasheet is empty. Please fill it before normalizing data."
		Print "Error message:"
		Print "The datasheet is empty. Please fill it before normalizing data."
		Return -1
	Endif

	Return 0

End

// Check if the number of entries in datasheet is equal to that of 1D waves
// Check if the sampleName on datasheet matches that of 1D waves
Function R2D_Error_DatasheetMatch1D()
	
	String IntList = WaveList("*_i", ";","DIMS:1,TEXT:0") //return a list of int in current datafolder
	IntList = R2D_skip_fit(IntList)  // skip fit results
	Variable numOf1D = itemsinlist(IntList)
	
	wave/Z/T Datasheet = ::Red2DPackage:Datasheet
	variable numOfRows = DimSize(Datasheet,0)
	
	Variable i
	String target
	String NameNotFound = ""
	Make/FREE/T/O/N=(numOfRows) DatasheetName = Datasheet[p][%ImageName]
	For(i=0; i<numOf1D; i++)
		target = RemoveEnding(StringFromList(i, IntList), "_i")
		FindValue/TEXT=(target) DatasheetName		
		If(V_value == -1) // V_value stores the index from FindValue
			NameNotFound = AddListItem(target, NameNotFound, ";", Inf)
		Endif
	Endfor 
	
	If(strlen(NameNotFound) > 0)
		Print "Error message:"
		Print NameNotFound + " was not found in the datasheet."
		Print "Please Check your 1D waves and datasheet."
		Print "Re-import the datasheet may resolve the problem."
		DoAlert 0, "One or more 1D intensity waves were not found in the datasheet. Please check the command line for help."
		Return -1
	Endif
		
	Return 0

End

Function R2D_Error_DatasheetExist2D()
	
	wave/Z/T Datasheet = :Red2DPackage:Datasheet
	variable numOfImages = DimSize(Datasheet,0)
	If(WaveExists(Datasheet) == 0)
		DoAlert 0, "No datasheet exists in the Red2DPackage folder."
		Print "Error message:"
		Print "No datasheet exists in the Red2DPackage folder."
		Return -1	
	Endif
	
	If(numOfImages == 0)
		DoAlert 0, "The datasheet is empty. Please fill it before normalizing data."
		Print "Error message:"
		Print "The datasheet is empty. Please fill it before normalizing data."
		Return -1
	Endif

	Return 0

End

Function R2D_Error_DatasheetMatch2D()
	
	Wave/T ImageList = :Red2DPackage:ImageList
	Variable numOfImages = DimSize(ImageList,0)
	
	wave/Z/T Datasheet = :Red2DPackage:Datasheet
	variable numOfRows = DimSize(Datasheet,0)
	
	String target
	String NameNotFound = ""
	Make/FREE/T/O/N=(numOfRows) DatasheetName = Datasheet[p][%ImageName]
	
	Variable i
	For(i=0; i<numOfImages; i++)
		target = ImageList[i]
		FindValue/TEXT=(target) DatasheetName		
		If(V_value == -1) // V_value stores the index from FindValue
			NameNotFound = AddListItem(target, NameNotFound, ";", Inf)
		Endif
	Endfor 
	
	If(strlen(NameNotFound) > 0)
		Print "Error message:"
		Print NameNotFound + " was not found in the datasheet."
		Print "Please Check your 1D waves and datasheet."
		Print "Re-import the datasheet may resolve the problem."
		DoAlert 0, "One or more images were not found in the datasheet. Please check the command line for help."
		Return -1
	Endif
		
	Return 0

End


// *************************
// Make an image list, deeply used throughout R2D package.
// *************************

Function R2D_CreateImageList(order)  // Create an image list based on the selected order: 1 for name, 2 for date created
	variable order
	
	// Create two list byData and byName
	NewDataFolder/O Red2DPackage
	String ListByDate = Wavelist("*",";","DIMS:2,TEXT:0")
	String ListByName = SortList(ListByDate, ";", 16)	// Sort the list by name (default wavelist get by date created)
	Variable NumInList = itemsinlist(ListByDate) // Get number of items in List
	
	// Create a textWave "ImageList" and a string "U_ImageList" to store the imagelist with selected order
	If(NumInList==0)
		Make/T/O/N=0 :Red2DPackage:ImageList  // imagelist wave
		String/G :Red2DPackage:U_ImageList = ""  // imagelist string
		Print "No image exists in current datafolder."
		Return -1
	Else
		If(order == 1)
			Wave/Z/T reftw = ListToTextWave(ListByName,";")  // ListToTextWave returns a FREE wave
			Duplicate/O/T reftw, :Red2DPackage:ImageList
			String/G :Red2DPackage:U_ImageList = ListByName
		Elseif(order == 2)
			Wave/Z/T reftw = ListToTextWave(ListByDate,";")  // ListToTextWave returns a FREE wave
			Duplicate/O/T reftw, :Red2DPackage:ImageList
			String/G :Red2DPackage:U_ImageList = ListByDate
		Endif
	Endif
					
End

// *************************
// Cleanup names, mostly used for file loading.
// *************************
Function/S R2D_CleanupName(str)
	string str
	
//	string str1
	str = RemoveEnding(str,".tif") // Remove the extension
	str = RemoveEnding(str,".tiff") // Remove the extension
	str = RemoveEnding(str,".edf") // Remove the extension
	str = RemoveEnding(str,".txt") // Remove the extension
	str = RemoveEnding(str,".asc") // Remove the extension
	str = RemoveEnding(str,".dat") // Remove the extension
	str = RemoveEnding(str,".mdat") // Remove the extension
	str = RemoveEnding(str,".sdat") // Remove the extension
	str = CleanupName(str,0)  // adopt strict name rules, e.g. remove .,/ * and so on.

	/// Do not use uniquename here because I prefer to overwrite the images with the same name.
	/// Users should avoid use the same name for the images.
	
	return str
End

// *** simple timer
Function R2D_SimpleTimer(trigger)
	variable trigger
	
	variable t1
	variable seconds
	if(trigger == 1)
		seconds = StopMSTimer(t1)
		t1 = StartMSTimer
//		print t1
	else
		seconds = StopMSTimer(t1)/1E6
		print "Simple Timer", seconds, "s"
	endif

End