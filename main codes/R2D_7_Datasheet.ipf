#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


/// This function deterimines the path of the datasheet.
Function/S GetDatasheetPath()
	/// I do not have to pass any variable to this function.
	/// The variable for this function is the current selected datafolder.
	
	String Datasheet_Path  // string to store the path
	If(R2D_Error_1Dexist(NoMessage = 1) != -1)  // if in 1D folder. the parameter NoMessage = 1 is an optional flag to suppress the error message.
		NewDataFolder/O ::Red2DPackage  // this prevents bugs caused by irregular manupulation
		Datasheet_Path = "::Red2DPackage:Datasheet"
	
	Elseif(R2D_Error_ImagesExist(NoMessage = 1) != -1)  // if in 2D folder
		NewDataFolder/O :Red2DPackage  // this prevents bugs caused by irregular manupulation
		Datasheet_Path = ":Red2DPackage:Datasheet"

	Else	// if in wrong folder
		Abort "Wrong datafolder. Please set datafolder to an image folder or a 1D waves folder."
	Endif
	
	return Datasheet_Path

End

/// This function returns the 2D imagelist or 1D profile list as a target list
Function/S GetTargetListPath()
	/// I do not have to pass any variable to this function.
	/// The variable for this function is the current selected datafolder.
	
	string targetlist_path
	If(R2D_Error_1Dexist(NoMessage = 1) != -1)  // if in 1D folder. the parameter 1 is an optional flag to suppress the error message.
		/// create a intensity list wave in the 1D datafolder
		Wave/Z/T IntList = ListToTextWave(WaveList("*_i", ";","DIMS:1,TEXT:0"), ";") //return a list of int in current datafolder, free wave.
		variable numOfTargets
		numOfTargets = DimSize(IntList, 0)
		Variable i
		For(i=0; i<numOfTargets; i++)
			IntList[i] = RemoveEnding(IntList[i], "_i")
		Endfor
		Duplicate/O/T IntList, ::Red2DPackage:IntList
		
		/// get the path of the intlist wave
		targetlist_path = GetWavesDataFolder(::Red2DPackage:IntList, 2)
	
	Elseif(R2D_Error_ImagesExist(NoMessage = 1) != -1)  // if in 2D folder
		R2D_CreateImageList(1) // create an imagelist. 1 for name order, 2 for created date order
		targetlist_path = GetWavesDataFolder(:Red2DPackage:Imagelist, 2) // get the path of the imagelist

	Else	// if in wrong folder
		Abort "Wrong datafolder. Please set datafolder to an image folder or a 1D waves folder."
	Endif
	
	return targetlist_path

End

/// Create a new empty datasheet
Static Function MakeNewDatasheet(targetList_path, Datasheet_path)
	string targetList_path
	string Datasheet_path
	
	wave/T targetList = $targetList_path
	variable numOftargets = DimSize(targetList, 0)
	Make/O/T/N=(numOftargets, 8) $Datasheet_path
	wave/Z/T Datasheet = $Datasheet_path

	Datasheet = "" // Initialize
	SetDimLabel 1, 0, SampleName, Datasheet
	SetDimLabel 1, 1, ImageName, Datasheet
	SetDimLabel 1, 2, Time_s, Datasheet
	SetDimLabel 1, 3, Trans, Datasheet
	SetDimLabel 1, 4, Thick_cm, Datasheet
	SetDimLabel 1, 5, Comment0, Datasheet
	SetDimLabel 1, 6, Comment1, Datasheet
	SetDimLabel 1, 7, Comment2, Datasheet
	Datasheet[][%ImageName]=targetList[p]

End

Function R2D_CreateOrShowDatasheet(type)
	variable type  // 0, create new datasheet; 1, show existing datasheet; 2, append newly added images
	
	String Datasheet_Path = GetDatasheetPath()  // get path of the datasheet. if in a wrong datafolder, return an error and abort.
	String TargetList_Path =  GetTargetListPath()  // get the path of the imagelist or the intlist, as targetlist. if in a wrong datafolder, return an error and abort.
	Wave/T Targetlist = $TargetList_Path  // make a wave reference of the targetlist from the its path
	
	//If no error found
	If(type == 0)  // create new
		If(WaveExists($Datasheet_Path) == 1)  // check if old datasheet exist
			DoAlert 1, "There is an existing datasheet. Do you want to replace it?"
			If(V_flag == 2) // No clicked
				Print "User canceled"
				return 0
			Endif
		Endif

		// if user did not cancel procedure, create a new datasheet
		MakeNewDatasheet(TargetList_Path, Datasheet_Path)  // create a new datasheet
		wave/T Datasheet = $Datasheet_Path  // get the wave reference for latter use

	Elseif(type == 1) // show existing
		wave/Z/T Datasheet = $Datasheet_Path
		If(!Waveexists(Datasheet))
			Abort "No Datasheet exist."
		Endif
		
	Elseif(type == 2) // update existing
		Duplicate/O/T/FREE $Datasheet_Path, old_datasheet  // store the old datasheet
		Make/FREE/T/O/N=(DimSize(old_datasheet, 0)) old_imagenames = old_datasheet[p][%ImageName]  // create a temp wave to store the image name in old sheet
		
		MakeNewDatasheet(TargetList_Path, Datasheet_Path)  // create a new datasheet
		wave/T Datasheet = $Datasheet_Path  // get the wave reference of the datasheet
		
		variable i
		variable numOftargets = DimSize(TargetList, 0)  // number of images in new datasheet
		For(i=0; i<numOftargets; i++)
			FindValue/TEXT=TargetList[i]/TXOP=4 old_imagenames  // check if the image exists in old datasheet
			If(V_value != -1) // transfer parameters from old datasheet if exist
				Datasheet[i][%SampleName] = old_datasheet[V_value][%SampleName]
				Datasheet[i][%Time_s] = old_datasheet[V_value][%Time_s]
				Datasheet[i][%Trans] = old_datasheet[V_value][%Trans]
				Datasheet[i][%Thick_cm] = old_datasheet[V_value][%Thick_cm]
				Datasheet[i][%Comment0] = old_datasheet[V_value][%Comment0]
				Datasheet[i][%Comment1] = old_datasheet[V_value][%Comment1]
				Datasheet[i][%Comment2] = old_datasheet[V_value][%Comment2]
			Endif
			// if not found in old datasheet, leave the corresponding cells of the targetlist empty.
		Endfor
		
	Endif
		
	/// Create a table window for new datasheet if the table does not exist.
	String ParentFolderName = ParseFilePath(0, GetWavesDataFolder(datasheet, 1), ":", 1, 1) // Get the datafolder name of parent directory
	String DataSheetTableName = "Datasheet_" + ParentFolderName
//	DoWindow $DataSheetTableName   // /F means 'bring to front if it exists'
//	// 2025-11-20 a datasheet with the table name , but from a different folder, may exist. To avoid confusion, kill the table with the same name first.
//	If (V_flag == 0) // window does not exist
//		Edit/K=1/N=$DataSheetTableName Datasheet.ld
//	else	// if window exists
		KillWindow $DataSheetTableName
		Edit/K=1/N=$DataSheetTableName Datasheet.ld
		DoWindow/F $DataSheetTableName
//	Endif
	
End



/// Import datasheet from an excel file
Function R2D_ImportDatasheet([path, noedit])
	string path  // path of datasheet in pc
	variable noedit  //0 for edit, 1 for noedit

	String Datasheet_Path = GetDatasheetPath()  // get path of the datasheet. if in a wrong datafolder, return an error and abort.
	String TargetList_Path =  GetTargetListPath()  // get the path of the imagelist or the intlist, as targetlist. if in a wrong datafolder, return an error and abort.
	Wave/T Targetlist = $TargetList_Path  // make a wave reference of the targetlist from the its path
	variable numInIgor = DimSize(Targetlist, 0)
	

	/// set the symbolic path of the datasheet
	string excelpath
	If(ParamIsDefault(path))  // path not specified
	
		/// check if the datasheet already exist in igor and prompt a dialog to ask user for the permisstion to overwrite the existing datasheet.
		If(WaveExists($Datasheet_Path) == 1)
			DoAlert 1, "There is an existing datasheet. Do you want to replace it?"
			If(V_flag == 2) // No clicked
				Print "User canceled"			
				return 0
			Endif
		Endif
		
		/// Display dialog looking for file or load preset path.
		Variable refNum
		String filters = "Excel Files (*.xls,*.xlsx,*.xlsm):.xls,.xlsx,.xlsm;"
		filters += "All Files:.*;"
		Open/D/R /F=filters refNum
		if (strlen(S_fileName) == 0)		// User canceled?
			Print "User canceled"
			return 0
		endif
		excelpath = S_fileName
	Else  // if path is specified
		excelpath = path
	Endif

	// Load excel file. row 1 is wave names.
	XLLoadWave/S=""/COLT="T"/W=1/O/V=0/K=0/Q excelpath
	if (V_flag == 0)
		Print "User canceled"
		return 0			// User canceled
	endif
	
	// Make reference for loaded waves. The names on the right hand are written in excel sheet.
	wave/T w0 = SampleName
	wave/T w1 = ImageName
	wave/T w2 = Time_s
	wave/T w3 = Trans
	wave/T w4 = Thick_cm
	wave/T w5 = Comment0
	wave/T w6 = Comment1
	wave/T w7 = Comment2
	variable numInExcel = DimSize(w1,0)  // get the size of the excel file.
	
	// correct ImageName to follow strict name rule
	Variable i
	For(i=0; i<numInExcel; i++)
		w1[i] = R2D_CleanupName(w1[i])
	Endfor
	
	// Create a new datasheet
//	MakeNewDatasheet(Imagelist_IgorPath, Datasheet_Path)
	Make/O/T/N=(numInIgor, 8) $Datasheet_Path
	wave/Z/T Datasheet = $Datasheet_Path

	Datasheet = "" // Initialize
	SetDimLabel 1, 0, SampleName, Datasheet
	SetDimLabel 1, 1, ImageName, Datasheet
	SetDimLabel 1, 2, Time_s, Datasheet
	SetDimLabel 1, 3, Trans, Datasheet
	SetDimLabel 1, 4, Thick_cm, Datasheet
	SetDimLabel 1, 5, Comment0, Datasheet
	SetDimLabel 1, 6, Comment1, Datasheet
	SetDimLabel 1, 7, Comment2, Datasheet

	Datasheet[][%ImageName]=Targetlist[p]
	Print "A datasheet is loaded from", excelpath

	//	Search the corresponding information from Excel sheet based on the ImageName in datasheet on Igor.
	variable IndexInExcel
	String tgNam
	For(i = 0 ;i < numInIgor; i++)
		tgNam = Datasheet[i][%ImageName]
		FindValue/TEXT=tgNam/TXOP=4 w1
		
		If(V_value == -1)
			Print tgNam,"is not found in the datasheet."
		Else
			IndexInExcel = V_value
			
			If(WaveExists(w0) != 0)
				Datasheet[i][%SampleName] = w0[IndexInExcel]
			Endif
			
			If(WaveExists(w2) != 0)
				Datasheet[i][%Time_s] = num2str( RoundDigits(str2num(w2[IndexInExcel]), 4) )
			Endif
			
			If(WaveExists(w3) != 0)
				Datasheet[i][%Trans] = num2str( RoundDigits(str2num(w3[IndexInExcel]), 4) )
			Endif
			
			If(WaveExists(w4) != 0)
				Datasheet[i][%Thick_cm] = num2str( RoundDigits(str2num(w4[IndexInExcel]), 4) )
			Endif
			
			If(WaveExists(w5) != 0)
				Datasheet[i][%Comment0] = w5[IndexInExcel]
			Endif
			
			If(WaveExists(w6) != 0)
				Datasheet[i][%Comment1] = w6[IndexInExcel]
			Endif
			
			If(WaveExists(w7) != 0)
				Datasheet[i][%Comment2] = w7[IndexInExcel]
			Endif
			
		Endif
	Endfor
	
	/// Kill all loaded waves.
	variable NumInList = ItemsInList(S_waveNames)
	string loadedwave
	For(i=0; i< NumInList; i++)
		loadedwave = StringFromList(i, S_waveNames)
		KillWaves $loadedwave
	Endfor
	
	/// Create a table for datasheet

	String ParentFolderName = ParseFilePath(0, GetWavesDataFolder(datasheet, 1), ":", 1, 1) // Get the datafolder name of parent directory
	String DataSheetTableName = "Datasheet_" + ParentFolderName
	DoWindow /F $DataSheetTableName   // /F means 'bring to front if it exists'
	If (V_flag == 0 && noedit == 0) // window does not exist, and noedit is false 0.
		Edit/K=1/N=$DataSheetTableName Datasheet.ld
	Endif
	
End

Function RoundDigits(val, digits)
	variable val
	variable digits
	
	variable output
	output = round(val*10^digits)/10^digits
	
	return output

End
