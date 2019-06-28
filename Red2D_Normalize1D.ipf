#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <WaveSelectorWidget>
#include <PopupWaveSelector>

/// Create Data sheet for the normalization
Function Red2D_CreUpdDatasheet()
	
	/// Check if in 1D datafolder
	If(DataFolderExists("::Red2DPackage") == 0)
		Abort "You may in a wrong datafolder. Move to 1D datafolder."
	ElseIf(CmpStr(GetDataFolder(0), "Red2DPackage") == 0)
		Abort "You may in a wrong datafolder. Move to 1D datafolder."
	Endif
	
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder ::Red2DPackage
	Wave/T ImageList
	Variable numOfImages = Dimsize(ImageList,0)

	/// Check in 1D data folder again.
	If(numOfImages == 0)
		SetDataFolder saveDFR
		Abort "ImageList was not found in Red2DPackage.\rPlease set datafolder to where the image exist and then click refresh button on display images panel to recreate an ImageList."
	Endif
	
	/// Create a new datasheet if not exists. If exist, just make a new table.
	If(WaveExists($"Datasheet") == 0) // wave reference error occurs if I type Datasheet or declare it above.
		Make/O/T/N=(numOfImages, 8) Datasheet
		Datasheet = "" // Initialize
		SetDimLabel 1, 0, ImageName, Datasheet
		SetDimLabel 1, 1, Time_s, Datasheet
		SetDimLabel 1, 2, Trans, Datasheet
		SetDimLabel 1, 3, Thick_cm, Datasheet
		SetDimLabel 1, 4, Comment0, Datasheet
		SetDimLabel 1, 5, Comment1, Datasheet
		SetDimLabel 1, 6, Comment2, Datasheet
		SetDimLabel 1, 7, Comment3, Datasheet
		Datasheet[][%ImageName]=ImageList[p] // add image name automatically
	Endif
	
	KillWindow/Z Datasheet_Table // kill old one if exists
	Edit/N=Datasheet_Table Datasheet.ld // show new one
	
	SetDataFolder saveDFR
	
End

/// Load datasheet from an excel file
Function Red2D_ImportDatasheet()
	/// Check if in 1D datafolder
	If(DataFolderExists("::Red2DPackage") == 0)
		Abort "You may in a wrong datafolder. Move to 1D datafolder."
	ElseIf(CmpStr(GetDataFolder(0), "Red2DPackage") == 0)
		Abort "You may in a wrong datafolder. Move to 1D datafolder."
	Endif
	
	/// Move to packagefolder
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder ::Red2DPackage
	
	/// Check if there is already a datasheet.
	wave/T Datasheet
	If(WaveExists(datasheet) == 1)
		DoAlert 1, "You already have a datasheet for this dataset. Do you want to delet it and make a new one?"
		If(V_flag != 1)
			Print "User canceld."
			SetDataFolder saveDFR
			return -1
		Endif
	Endif	
	
	// Display dialog looking for file.
	Variable refNum
	String filters = "Excel Files (*.xls,*.xlsx,*.xlsm):.xls,.xlsx,.xlsm;"
	filters += "All Files:.*;"
	Open/D/R /F=filters refNum
	if (strlen(S_fileName) == 0)		// User cancelled?
		SetDataFolder saveDFR
		return -1
	endif
	string excelpath = S_fileName

	// Load excel file. row 1 is wave names.
	XLLoadWave/S=""/COLT="T"/W=1/O/V=0/K=0/Q S_fileName
	if (V_flag == 0)
		SetDataFolder saveDFR
		return -1			// User cancelled
	endif
	
	// Make reference for loaded waves
	wave/T ImageList
	wave/T w0 = ImageName
	wave/T w1 = Time_s
	wave/T w2 = Trans
	wave/T w3 = Thick_cm
	wave/T w4 = Comment0
	wave/T w5 = Comment1
	wave/T w6 = Comment2
	wave/T w7 = Comment3
	
	variable numInIgor = DimSize(ImageList,0)
	variable numInExcel = DimSize(w0,0)
	
	/// Create a new datasheet
	KillWindow/Z Datasheet_Table // kill old table if exists
	Make/O/T/N=(numInIgor, 8) Datasheet
	Datasheet = "" // Initialize
	SetDimLabel 1, 0, ImageName, Datasheet
	SetDimLabel 1, 1, Time_s, Datasheet
	SetDimLabel 1, 2, Trans, Datasheet
	SetDimLabel 1, 3, Thick_cm, Datasheet
	SetDimLabel 1, 4, Comment0, Datasheet
	SetDimLabel 1, 5, Comment1, Datasheet
	SetDimLabel 1, 6, Comment2, Datasheet
	SetDimLabel 1, 7, Comment3, Datasheet

	Datasheet[][%ImageName] = ImageList[p] // fill ImageName
	
	variable i, IndexInExcel
	String tgNam
	For(i = 0 ;i < numInIgor; i++)
		tgNam = Datasheet[i][%ImageName]
		FindValue/TEXT=tgNam/TXOP=4 w0
		
		If(V_value == -1)
			Print tgNam,"is not found in the datasheet."
		Else
			IndexInExcel = V_value
			
			If(WaveExists(w1) != 0)
				Datasheet[i][%Time_s] = w1[IndexInExcel]
			Endif
			
			If(WaveExists(w2) != 0)
				Datasheet[i][%Trans] = w2[IndexInExcel]
			Endif
			
			If(WaveExists(w3) != 0)
				Datasheet[i][%Thick_cm] = w3[IndexInExcel]
			Endif
			
			If(WaveExists(w4) != 0)
				Datasheet[i][%Comment0] = w4[IndexInExcel]
			Endif
			
			If(WaveExists(w5) != 0)
				Datasheet[i][%Comment1] = w5[IndexInExcel]
			Endif
			
			If(WaveExists(w6) != 0)
				Datasheet[i][%Comment2] = w6[IndexInExcel]
			Endif
			
			If(WaveExists(w7) != 0)
				Datasheet[i][%Comment3] = w7[IndexInExcel]
			Endif
			
		Endif
	Endfor
	
	Edit/N=Datasheet_Table Datasheet.ld
	
	/// Kill all loaded waves.
	variable NumInList = ItemsInList(S_waveNames)
	string loadedwave
	For(i=0; i< NumInList; i++)
	loadedwave = StringFromList(i, S_waveNames)
	KillWaves $loadedwave
	Endfor
	
	SetDataFolder saveDFR
	
	Print "Datasheet is loaded from", excelpath
End


///////////Time and Transmittance correction//////////////
Function TimeAndTrans()
	
	/////////////////////GET 1D WAVELIST TO NORMALIZE/////////////////////
	String List1D = WaveList("!*_ERR", ";", "TEXT:0" )
	List1D = RemoveFromList("qq", List1D)
	List1D = RemoveFromList("theta", List1D)
	
	String List1D_ERR = WaveList("*_ERR", ";", "TEXT:0" )
	List1D_ERR = RemoveFromList("qq", List1D_ERR)
	List1D_ERR = RemoveFromList("theta", List1D_ERR)
	
	Variable numOf1D = ItemsInList(List1D,";")

	//////////////////////////GET INFO FROM DATASHEET////////////////////////////
	//@1D folder.
	DFREF saveDFR = GetDataFolderDFR()
	DFREF ParentDFR=$(GetDataFolder(1, saveDFR)+":")
	SetdataFolder ParentDFR
		//@Parent Datafolder. Create wavereference.
		wave/T Datasheet = :Red2DPackage:Datasheet
		variable numOfImages = DimSize(Datasheet,0)
	//@1D folder.
	SetdataFolder saveDFR
	//Make temporay waves to store the info from datasheet.
	Make/T/O/N=(numOfImages) ImageName = Datasheet[p][%ImageName]
	Make/T/O/N=(numOfImages) Time_s = Datasheet[p][%Time_s]
	Make/T/O/N=(numOfImages) Trans = Datasheet[p][%Trans]
	
	
	///////////////////////CHECKPOINT: IF DATASHEET MATCHES 1D WAVELIST///////////////////////
	If(numOf1D!=numOfImages)
		DoAlert 0, "Number of names in datasheet is incosistent with the number of 1D waves in current datafolder."
		Print "False"
		Killwaves ImageName, Time_s, Trans
		return -1
	Endif
	
	variable p
	For(p=0;p<numOf1D;p+=1)
		If(	StringMatch(StringFromList(p, List1D),ImageName[p]+"*") == 0)
			DoAlert 0, "1D waves in current datafolder do not match ImageName in datasheet. Check names and order in datasheet and 1D folder."
			Print "False"
			Killwaves ImageName, Time_s, Trans
			return -1
		Endif
	Endfor
	
	
	
	/////////////////////////////NORMALIZATION/////////////////////////////
	variable i
	String Name1D, Name1D_ERR, NewName, NewName_ERR
	For(i=0;i<numOf1D; i+=1)
		
		//Get target name from targetlist and remove the unncessary symbols.
		Name1D = StringFromList(i, List1D,";")
		Name1D_ERR = StringFromList(i, List1D_ERR,";")	
		Wave Wave1D = $Name1D
		Wave Wave1D_ERR = $(Name1D_ERR)
		
		//Do the correction.
		Wave1D = Wave1D/str2num(Time_s[i])/str2num(Trans[i])
		Wave1D_ERR = Wave1D_ERR/str2num(Time_s[i])/str2num(Trans[i])
		
		Print NameofWave(Wave1D) +"/"+ Time_s[i] +"/"+ Trans[i]
		Print NameofWave(Wave1D_ERR) +"/"+ Time_s[i] +"/"+ Trans[i]
				
		//Rename target.
		NewName = Name1D+"_tt"
		NewName_ERR = Name1D+"_tt_ERR" // I put ERR at the end because it is useful for other proc.
		Rename Wave1D, $(NewName)
		Rename Wave1D_ERR, $(NewName_ERR)
	Endfor
	
	Killwaves ImageName, Time_s, Trans
	Print "Success"
		
End


///////////////Cell subtraction////////////////
Function Cellsubtraction()

	Killwindow/Z CellsubtractionPanel
	NewPanel/K=1/W=(550,550,880,700) as "Cell subtraction"
	RenameWindow $S_name, CellsubtractionPanel
	
	TitleBox WSPopupTitle1,pos={92,25}, frame=0, fSize=14, title="Select the wave of cell"
	Button CellSelector,pos={39,50},size={250,25}, fSize=14
	MakeButtonIntoWSPopupButton("CellsubtractionPanel", "CellSelector", "CellPopupWaveSelectorNotify", options=PopupWS_OptionFloat)
	///MakeButtonIntoWSPopupButton is a builtin function in Igor Pro.
	
	Button bt0,pos={114,100},size={100,25}, fSize=14, proc=CellSubtractButtonProc,title="Subtract"
	
End

Function CellSubtractButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			/////////////////////////GET 1D WAVELIST TO NORMALIZE/////////////////////////
			String List1D = WaveList("!*_ERR", ";", "TEXT:0" )
			List1D = RemoveFromList("qq", List1D)
			List1D = RemoveFromList("theta", List1D)
	
			String List1D_ERR = WaveList("*_ERR", ";", "TEXT:0" )
			List1D_ERR = RemoveFromList("qq", List1D_ERR)
			List1D_ERR = RemoveFromList("theta", List1D_ERR)
	
			Variable numOf1D = ItemsInList(List1D,";")
			
			
			//////////////////////////////GET CELL WAVE////////////////////////////////
			String CellPath = PopupWS_GetSelectionFullPath("CellsubtractionPanel", "CellSelector")
			Duplicate/O $(CellPath), refcell
			Duplicate/O $(CellPath+"_ERR"), refcell_ERR
			
			wave testwave = $(StringFromList(0, List1D))
			If(Dimsize(refcell,0)!=Dimsize(testwave,0))
				DoAlert 0, "The number of points in the selected cell wave does not match that of 1D waves in current datafolder."
				Print "False"
				Killwaves refcell, refcell_ERR
				Return -1
			Endif

			///////////////////////////SUBTRACT CELL////////////////////////////////
			String Name1D, Name1D_ERR, NewName, NewName_ERR
			variable i
			For(i=0;i<numOf1D; i+=1)
				//Set reference of target wave in current folder. Only deal with waves having name in refname(Datasheet).
				Name1D = StringFromList(i, List1D,";")
				Name1D_ERR = StringFromList(i, List1D_ERR,";")	
				Wave Wave1D = $Name1D
				Wave Wave1D_ERR = $(Name1D_ERR)
		
				Wave1D -= refcell
				Wave1D_ERR = (Wave1D_ERR^2 + refcell_ERR^2)^0.5
				
				//refname is from Datasheet. TargetName is from Red1D.
				NewName = Name1D+"c"
				NewName_ERR = Name1D+"c_ERR" // I put ERR at the end because it is useful for other proc.
				Rename Wave1D, $(NewName)
				Rename Wave1D_ERR, $(NewName_ERR)	
			Endfor
	
			Killwaves refcell, refcell_ERR
			Killwindow CellsubtractionPanel
			Print "Success"
			Print CellPath
			Print "is subtracted from"
			Print List1D
					
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


/////////////////Thickness correction//////////////
Function ThickCorr()

	/////////////////////GET 1D WAVELIST TO NORMALIZE/////////////////////
	String List1D = WaveList("!*_ERR", ";", "TEXT:0" )
	List1D = RemoveFromList("qq", List1D)
	List1D = RemoveFromList("theta", List1D)
	
	String List1D_ERR = WaveList("*_ERR", ";", "TEXT:0" )
	List1D_ERR = RemoveFromList("qq", List1D_ERR)
	List1D_ERR = RemoveFromList("theta", List1D_ERR)
	
	Variable numOf1D = ItemsInList(List1D,";")

	//////////////////////////GET INFO FROM DATASHEET////////////////////////////
	//@1D folder.
	DFREF saveDFR = GetDataFolderDFR()
	DFREF ParentDFR=$(GetDataFolder(1, saveDFR)+":")
	SetdataFolder ParentDFR
		//@Parent Datafolder. Create wavereference.
		wave/T Datasheet = :Red2DPackage:Datasheet
		variable numOfImages = DimSize(Datasheet,0)
	//@1D folder.
	SetdataFolder saveDFR
	//Make temporay waves to store the info from datasheet.
	Make/T/O/N=(numOfImages) ImageName = Datasheet[p][%ImageName]
	Make/T/O/N=(numOfImages) Thick_cm = Datasheet[p][%Thick_cm]

	
	///////////////////////CHECKPOINT: IF DATASHEET MATCHES 1D WAVELIST///////////////////////
	If(numOf1D!=numOfImages)
		DoAlert 0, "Number of names in datasheet is incosistent with the number of 1D waves in current datafolder."
		Print "False"
		Killwaves ImageName, Thick_cm
		return -1
	Endif
	
	variable p
	For(p=0;p<numOf1D;p+=1)
		If(	StringMatch(StringFromList(p, List1D),ImageName[p]+"*") == 0)
			DoAlert 0, "1D waves in current datafolder do not match ImageName in datasheet. Check names and order in datasheet and 1D folder."
			Print "False"
			Killwaves ImageName, Thick_cm
			return -1
		Endif
	Endfor
	
	
	/////////////////////////////NORMALIZATION/////////////////////////////
	variable i
	String Name1D, Name1D_ERR, NewName, NewName_ERR
	For(i=0;i<numOf1D; i+=1)
		
		//Get target name from targetlist and remove the unncessary symbols.
		Name1D = StringFromList(i, List1D,";")
		Name1D_ERR = StringFromList(i, List1D_ERR,";")	
		Wave Wave1D = $Name1D
		Wave Wave1D_ERR = $(Name1D_ERR)
		
		//Do the correction.
		Wave1D /= str2num(Thick_cm[i])
		Wave1D_ERR /= str2num(Thick_cm[i])
		
		Print NameOfWave(Wave1D) +"/"+ Thick_cm[i]
		Print NameOfWave(Wave1D_ERR) +"/"+ Thick_cm[i]
				
		//Rename target.
		NewName = Name1D+"T"
		NewName_ERR = Name1D+"T_ERR" // I put ERR at the end because it is useful for other proc.
		Rename Wave1D, $(NewName)
		Rename Wave1D_ERR, $(NewName_ERR)
	Endfor
	
	Killwaves ImageName, Thick_cm
	Print "Success"
	
End



///////////////////Absolute intensity correction///////////////
Function LoadGC_NIST()
	
	String path
	path = SpecialDirPath("Igor Pro User Files",0,0,0) + "Igor Procedures:Red2D-v1.1:GC_CalibrationCurve_NIST.txt"
	GetFileFolderInfo/Z/Q path
	
	If(V_flag == -1) // user cancled
		Print "User canceled."
	Elseif(V_flag == 0) // file found
		Loadwave/G/N/O/Q path
		wave wave0
		wave wave1
		If(DatafolderExists("root:GC_NIST") == 0)
			NewDataFolder root:GC_NIST
		Endif
		Duplicate/O wave0, root:GC_NIST:q_GC_NIST
		Duplicate/O wave1, root:GC_NIST:I_GC_NIST
		Killwaves/Z wave0, wave1
		Print "Calibration curve of glassy carbon has been loaded successfully in a datafolder :root:GC_NIST."
		Print "The data is downloaded from https://www-s.nist.gov/srmors/view_detail.cfm?srm=3600"
	Else // file not found. show a dialog
		Loadwave/G/N/O/Q path
		If(V_flag == 0)
			Print "User canceled."
			return -1
		Endif
		wave wave0
		wave wave1
		If(DatafolderExists("root:GC_NIST") == 0)
			NewDataFolder root:GC_NIST
		Endif
		Duplicate/O wave0, root:GC_NIST:q_GC_NIST
		Duplicate/O wave1, root:GC_NIST:I_GC_NIST
		Killwaves/Z wave0, wave1
		Print "Calibration curve of glassy carbon has been loaded successfully in a datafolder :root:GC_NIST."
		Print "The data is downloaded from https://www-s.nist.gov/srmors/view_detail.cfm?srm=3600"
	Endif

End


Function AbsoluteNorm()
	
	///////////////TYPE CORRECTION FACTOR///////////////
	Variable AbsFactor
	Prompt AbsFactor, "ThisTime/Reference"		// Set prompt for x param
	DoPrompt "Enter AbsFactor", AbsFactor
	if (V_Flag)
		return -1								// User canceled
	endif
			
	/////////////////////GET 1D WAVELIST TO NORMALIZE///////////////////////
	String List1D = WaveList("!*_ERR", ";", "TEXT:0" )
	List1D = RemoveFromList("qq", List1D)
	List1D = RemoveFromList("theta", List1D)
	
	String List1D_ERR = WaveList("*_ERR", ";", "TEXT:0" )
	List1D_ERR = RemoveFromList("qq", List1D_ERR)
	List1D_ERR = RemoveFromList("theta", List1D_ERR)
	
	Variable numOf1D = ItemsInList(List1D,";")
				

	/////////////////////NORMALIZATION//////////////////////
	variable i
	String Name1D, Name1D_ERR, NewName, NewName_ERR
	For(i=0;i<numOf1D; i+=1)
		
		//Get target name from targetlist and remove the unncessary symbols.
		Name1D = StringFromList(i, List1D,";")
		Name1D_ERR = StringFromList(i, List1D_ERR,";")	
		Wave Wave1D = $Name1D
		Wave Wave1D_ERR = $(Name1D_ERR)
		
		//Do the correction.
		Wave1D /= AbsFactor
		Wave1D_ERR /= AbsFactor
		
		Print NameOfWave(Wave1D) +"/"+ num2str(AbsFactor)
		Print NameOfWave(Wave1D_ERR) +"/"+ num2str(AbsFactor)
				
		//Rename target.
		NewName = Name1D+"a"
		NewName_ERR = Name1D+"a_ERR" // I put ERR at the end because it is useful for other proc.
		Rename Wave1D, $(NewName)
		Rename Wave1D_ERR, $(NewName_ERR)
	Endfor
	
	Print "Success"
	
End


///////////////Solvent subtraction////////////////
Function SolventSubtraction()

	Killwindow/Z SolventSubtractionPanel
	NewPanel/K=1/W=(550,550,880,750) as "Solvent subtraction"
	RenameWindow $S_name, SolventSubtractionPanel
	
	TitleBox WSPopupTitle1,pos={81,25},frame=0, fSize=14, title="Select a wave of solvent"
	Button SolventSelector,pos={39,50},size={250,25}, fSize=14
	MakeButtonIntoWSPopupButton("SolventSubtractionPanel", "SolventSelector", "SolventPopupWaveSelectorNotify", options=PopupWS_OptionFloat)
	///MakeButtonIntoWSPopupButton is a builtin function in Igor Pro.
	
	SetVariable setvar0 value=K0, fSize=14, limits={0,1,0.01}, pos={84,100}, size={160,20}, title="Solvent fraction"
	
	Button bt0,pos={114,150},size={100,25}, fSize=14, proc=SolventSubtractButtonProc,title="Subtract"
	
End

Function SolventSubtractButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			/////////////////////////GET 1D WAVELIST TO NORMALIZE/////////////////////////
			String List1D = WaveList("!*_ERR", ";", "TEXT:0" )
			List1D = RemoveFromList("qq", List1D)
			List1D = RemoveFromList("theta", List1D)
	
			String List1D_ERR = WaveList("*_ERR", ";", "TEXT:0" )
			List1D_ERR = RemoveFromList("qq", List1D_ERR)
			List1D_ERR = RemoveFromList("theta", List1D_ERR)
	
			Variable numOf1D = ItemsInList(List1D,";")
			
			
			//////////////////////////////GET SOLVENT WAVE////////////////////////////////
			String SolventPath = PopupWS_GetSelectionFullPath("SolventSubtractionPanel", "SolventSelector")
			Duplicate/O $(SolventPath), refSolvent
			Duplicate/O $(SolventPath+"_ERR"), refSolvent_ERR
			
			wave testwave = $(StringFromList(0, List1D))
			If(Dimsize(refSolvent,0)!=Dimsize(testwave,0))
				DoAlert 0, "The number of points in the selected cell wave does not match that of 1D waves in current datafolder."
				Print "False"
				Killwaves refSolvent, refSolvent_ERR
				Return -1
			Endif

			///////////////////////////SUBTRACT CELL////////////////////////////////
			String Name1D, Name1D_ERR, NewName, NewName_ERR
			variable i
			For(i=0;i<numOf1D; i+=1)
				//Set reference of target wave in current folder. Only deal with waves having name in refname(Datasheet).
				Name1D = StringFromList(i, List1D,";")
				Name1D_ERR = StringFromList(i, List1D_ERR,";")	
				Wave Wave1D = $Name1D
				Wave Wave1D_ERR = $(Name1D_ERR)
		
				Wave1D -= refSolvent * K0 //K0 is Igor Builtin variable. Here we used K0 as the solvent fraction.
				Wave1D_ERR = (Wave1D_ERR^2 + (refSolvent_ERR*K0)^2)^0.5
				
				//refname is from Datasheet. TargetName is from Red1D.
				NewName = Name1D+"s"
				NewName_ERR = Name1D+"s_ERR" // I put ERR at the end because it is useful for other proc.
				Rename Wave1D, $(NewName)
				Rename Wave1D_ERR, $(NewName_ERR)	
			Endfor
	
			Killwaves refSolvent, refSolvent_ERR
			Killwindow SolventSubtractionPanel
			Print "Success"
			Print SolventPath + "*"+ num2str(K0)
			Print "is subtracted from"
			Print List1D
					
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End