#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// Check if the ImageList matches to the 2D waves in current data folder.
/// If not warn the user and stop this procedure.
Function Red2Dimagelistexist()
	
	Wave/T ImageList = :Red2DPackage:ImageList
	Variable numOfImages = DimSize(ImageList,0)
			
	/// Check if imagelist exist? User may select a wrong folder.
	If(numOFImages == 0 || waveexists(ImageList) == 0)
		DoAlert 0, "No ImageList. You may be in a wrong data folder."
		Print "False"
		return -1
	Endif
			
	/// If the waves specified on the imagelist exist? user may delete the images.
	Variable i
	For(i = 0; i < numOfImages; i++)
		If(Waveexists($(ImageList[i])) == 0)
			DoAlert 0, "Selected image does not exist in the ImageList. Try refreshing ImageList."
			Print "False"
			return -1
		Endif
	Endfor	
	
	return 0
end