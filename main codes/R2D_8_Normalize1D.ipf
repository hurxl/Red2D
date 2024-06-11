#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <WaveSelectorWidget>
#include <PopupWaveSelector>

/// Unique datafolder name
Function/S R2D_Unique1DDataFolder(suffix)
	string suffix

/// Duplicate datafolder to backup data before nomalization.
/// Because the traces on the graph are linked to the unique waves in the dfp0
/// duplicate it and then normalizing the new datafolder does not change the traces
/// Therefore, I need to rename the datafolder to make the traces change
/// The duplicated datafolder is for the backup. 
	
	String dfname0 = GetDataFolder(0)  // current df name
	String dfname1 = dfname0 + suffix	// new inital df name
	DFREF svdfr = GetDataFolderDFR()  // remember current folder
	SetdataFolder ::  // go to the parent folder
	If(DataFolderExists(dfname1))  // datafolder exist
		dfname1 = UniqueName(dfname1, 11, 1)  // make hte new df name unique; add sequential number if dfname1 already exists.
	Endif
	
	RenameDataFolder $dfname0, $dfname1
	DuplicateDataFolder $dfname1, $dfname0
	SetDataFolder svdfr  // go back to original datafolder
	
	return dfname1

End


///////////Time and transmission correction//////////////
Function TimeAndTrans1D()
		
	//////ERROR CHECKER///////
	If(R2D_Error_1Dexist() == -1)
		Abort
	Elseif(R2D_Error_DatasheetExist1D() == -1)
		Abort
	Elseif(R2D_Error_DatasheetMatch1D() == -1)
		Abort
	Endif
	//////////////////////////
	
	
	/////////////////////PREPARE TO NORMALIZE/////////////////////
	R2D_Unique1DDataFolder("TT")

	
	/////////////////////////////Get datasheet/////////////////////////////
	string IntList = WaveList("*_i", ";","DIMS:1,TEXT:0") //return a list of int in current datafolder
	IntList = R2D_skip_fit(IntList)
	variable numOf1D = ItemsInList(IntList)
	wave/T Datasheet = ::Red2DPackage:Datasheet
	
		/////////////////Calcualte thickness dependent transmission///////////////////
	///Create a corrected transmission wave with the same dimension as the intensity wave
	///According to Grillo, Soft Matter Characterization
	///Tr_corr = (mu*thick*f_2t)^-1*exp(-mu*thick)*(1-exp(-mu*thick*f_2t))
	///Tr_corr = (ee*f_2t)^-1*exp(-ee)*(1-exp(-ee*f_2t))
	///f_2t = -1 + 1/cos(theta2/180*pi)   //with same dimension as the intensity wave, do not depend on sample
	wave theta2 = $(RemoveEnding(StringFromList(0, IntList), "_i") + "_2t")
	If(waveexists(theta2))
		Duplicate/FREE/O/D theta2, f_2t, Tr_corr
		f_2t = -1 + 1/cos(theta2/180*pi)  // independent of sample
		Tr_corr = 1  // initialize
	Else
		wave temp_i = $(StringFromList(0, IntList))
		Duplicate/FREE/O/D temp_i, Tr_corr
		Tr_corr = 1
	Endif
	
	/////////////////////////////NORMALIZATION/////////////////////////////
	String targetName
	Make/FREE/T/O/N=(DimSize(Datasheet, 0)) ImageName = Datasheet[p][%ImageName]
	Variable Time_s
	Variable Trans
	Variable ee
	Print "Start time and transmission correction..."
	Variable i
	For(i=0;i<numOf1D; i+=1)
		
		/// Get target name from targetlist and remove the unncessary symbols.
		targetName = RemoveEnding(StringFromList(i, IntList), "_i")
		Wave Wave1D = $(targetName + "_i")
		Wave Wave1D_s = $(targetName + "_s")
		
		// Get time and trans
		FindValue/TEXT=(targetName) ImageName		// One wave must be found here because we have checked the consistence bwteen the datasheet and 1D waves in the beginning.
		Time_s = str2num(Datasheet[V_value][%Time_s])
		Trans = str2num(Datasheet[V_value][%Trans])
		ee = -ln(trans)
		If(waveexists(theta2))
			If(ee == 0) // when trans = 1, ee = 0. The denominator in the trans correction equation becomes 0.
				Tr_corr = 1  // To avoid the problem, we directly put the transmission in Tr_thick.
			Else
				Tr_corr = (ee*f_2t)^-1*exp(-ee)*(1-exp(-ee*f_2t))
			Endif
		Else
			Tr_corr = Trans
		Endif
		
		/// Do the correction.
		Wave1D = Wave1D/Time_s/Tr_corr
		Wave1D_s = Wave1D_s/Time_s/Tr_corr

		Print NameofWave(Wave1D) +"/Time_s "+ num2str(Time_s) +"/Scattering-angle-corrected-Trans "+ num2str(Trans)
		Print NameofWave(Wave1D_s) +"/Time_s "+ num2str(Time_s) +"/Scattering-angle-corrected-Trans "+ num2str(Trans)

	Endfor
	
	Print "Time and transmission correction completes..."
		
End



///////////////Cell subtraction////////////////
Function Cellsubtraction1D()

	//////ERROR CHECKER///////
	If(R2D_Error_1Dexist() == -1)
		Abort
//	Elseif(R2D_Error_DatasheetExist1D() == -1)
//		Abort
//	Elseif(R2D_Error_DatasheetMatch1D() == -1)
//		Abort
	Endif
	//////////////////////////

	Killwindow/Z Cellsubtraction1DPanel
	NewPanel/K=1/W=(100,100,500,250) as "Cell subtraction"
	RenameWindow $S_name, Cellsubtraction1DPanel
	
	TitleBox WSPopupTitle1,pos={80,23}, frame=0, fSize=14, title="Select a wave of cell or air to subtract"
	Button CellSelector,pos={30,50},size={340,23}, fSize=14
	MakeButtonIntoWSPopupButton("Cellsubtraction1DPanel", "CellSelector", "CellPopupWaveSelectorNotify", popupWidth = 400, popupHeight = 600, options=PopupWS_OptionFloat)
	PopupWS_MatchOptions("Cellsubtraction1DPanel", "CellSelector", matchStr = "*i", listoptions = "DIMS:1,TEXT:0")
	PopupWS_SetPopupFont("Cellsubtraction1DPanel", "CellSelector", fontsize = 13)
	///MakeButtonIntoWSPopupButton is a builtin function in Igor Pro.
	Button bt0,pos={150,100},size={110,23}, fSize=14, proc=CellSubtractButtonProc,title="Subtract Cell"
	
End

Function CellSubtractButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			

			String IntList = WaveList("*_i", ";","DIMS:1,TEXT:0") //return a list of int in current datafolder
			IntList = R2D_skip_fit(IntList)
			Variable numOf1D = itemsinlist(IntList)
			
			//////////////////////////////GET CELL WAVE////////////////////////////////
			String CellPath = PopupWS_GetSelectionFullPath("Cellsubtraction1DPanel", "CellSelector")
			If(cmpstr(CellPath, "(no selection)", 0) == 0)
				Print "False"
				Abort "No selection."
			Endif
			Duplicate/O/FREE $(CellPath), refcell
			Duplicate/O/FREE $(RemoveEnding(CellPath,"_i") + "_s"), refcell_s
			
			wave testwave = $(StringFromList(0, IntList))
			If(Dimsize(refcell,0) != Dimsize(testwave,0))	
				Print "False"
				Killwaves refcell, refcell_s
				Abort "1D waves in current datafolder do not match ImageName in datasheet. ImageName must have the same order as 1D waves shown in data browser."
			Endif
			
			/// Duplicate datafolder to backup data before nomalization.
			R2D_Unique1DDataFolder("c")

			///////////////////////////SUBTRACT CELL////////////////////////////////
			variable i
			String targetName
			For(i=0;i<numOf1D; i+=1)
				//Set reference of target wave in current folder. Only deal with waves having name in refname(Datasheet).
				targetName = RemoveEnding(StringFromList(i, IntList), "_i")
				Wave Wave1D = $(targetName + "_i")
				Wave Wave1D_s = $(targetName + "_s")

				// Subtract cell
				Wave1D -= refcell
				Wave1D_s = (Wave1D_s^2 + refcell_s^2)^0.5
				
			Endfor
	
			Killwindow Cellsubtraction1DPanel
			Print CellPath
			Print "was subtracted from"
			Print IntList
			
			Print "Cell/air subtraction completes..."
					
			break
		case -1: // control being killed
			break
	endswitch
	
	return 0
End


/////////////////Thickness correction//////////////
Function ThickCorr1D()
	
	//////ERROR CHECKER///////
	If(R2D_Error_1Dexist() == -1)
		Abort
	Elseif(R2D_Error_DatasheetExist1D() == -1)
		Abort
	Elseif(R2D_Error_DatasheetMatch1D() == -1)
		Abort
	Endif
	//////////////////////////
	
	/////////////////////PREPARE TO NORMALIZE/////////////////////
	R2D_Unique1DDataFolder("t")
	
	
	/////////////////////////////NORMALIZATION/////////////////////////////
	string IntList = WaveList("*_i", ";","DIMS:1,TEXT:0") //return a list of int in current datafolder
	IntList = R2D_skip_fit(IntList)
	variable numOf1D = ItemsInList(IntList)
	wave/T Datasheet = ::Red2DPackage:Datasheet
	String targetName
	Make/FREE/T/O/N=(numOf1D) ImageName = Datasheet[p][%ImageName]
	variable i
	Variable Thick_cm
	For(i=0;i<numOf1D; i+=1)
		
		//Get target name from targetlist and remove the unncessary symbols.
		targetName = RemoveEnding(StringFromList(i, IntList), "_i")
		Wave Wave1D = $(targetName + "_i")
		Wave Wave1D_s = $(targetName + "_s")
		
		// Get Thick_cm
		FindValue/TEXT=(targetName) ImageName		// One wave must be found here because we have checked the consistence bwteen the datasheet and 1D waves in the beginning.
		Thick_cm = str2num(Datasheet[V_value][%Thick_cm])
		
		//Do the correction.
		Wave1D /= Thick_cm
		Wave1D_s /= Thick_cm
		
		Print NameOfWave(Wave1D) +"/"+ num2str(Thick_cm)
		Print NameOfWave(Wave1D_s) +"/"+ num2str(Thick_cm)

	Endfor
	
	Print "Thickness correction completes..."
	
End



///////////////////Absolute intensity correction///////////////
Function LoadGC_NIST(type)
	string type  //SAXS or SANS
	
	String path
	path = FindAfile("GC_CalibrationCurve_NIST_SRM3600", ".txt")
	
	If(strlen(path) == 0)
		Print "File not found."
		Print "You can download the calibration curve from https://www-s.nist.gov/srmors/view_detail.cfm?srm=3600"
	Else
		Loadwave/G/N/O/Q path
		wave wave0
		wave wave1
		wave wave2
		If(cmpstr(type, "SANS") == 0)
			wave1 /= 6.409  // 6.409 is the scaling factor to convert the SAXS profile to a SANS profile, obtained from NIST data sheet.
		Endif
		If(DatafolderExists("root:GC_NIST") == 0)
			NewDataFolder root:GC_NIST
		Endif
		Duplicate/O wave0, root:GC_NIST:gc_nist_ref_q
		Duplicate/O wave1, root:GC_NIST:gc_nist_ref_i
		Duplicate/O wave2, root:GC_NIST:gc_nist_ref_s
		Killwaves/Z wave0, wave1, wave2
		Print "Calibration curve of glassy carbon has been loaded successfully in a datafolder :root:GC_NIST."
		Print "The data was downloaded from https://www-s.nist.gov/srmors/view_detail.cfm?srm=3600"
	Endif
	
	DoAlert 1, "Do you want to append the loaded GC profiles on the top graph?"
	If(V_flag == 1)
		wave xwave = XWaveRefFromTrace("",StringFromList(0,TraceNameList("",";",5)))
//		variable qOR2t = StringMatch(NameOfWave(xwave), "*_2t")  // q for 0, s for 1
//		qOR2t = 0 // 2021-05-04 currently, I did not have the procedure to create 2t wave for GC, which depends on wavelength.
		
		DFREF savDF = GetDataFolderDFR()
		SetDataFolder root:GC_NIST
		R2D_Display1D(1, "_q")  //1 indicates append
		SetDataFolder savDF
	Endif
	
End

Function LoadGC_AlfaAesar(type)
	String type  // SAXS or SANS
	
	String path
	path = FindAfile("GC_CalibrationCurve_AlfaAesar", ".txt")
	
	If(strlen(path) == 0)
		Print "File not found."
		Print "You can download the calibration curve from https://www-s.nist.gov/srmors/view_detail.cfm?srm=3600"
	Else
		Loadwave/G/N/O/Q path
		wave wave0
		wave wave1
		wave wave2
		If(cmpstr(type, "SANS") == 0)
			wave1 /= 6.409  // 6.409 is the scaling factor to convert the SAXS profile to a SANS profile, obtained from NIST data sheet.
		Endif
		If(DatafolderExists("root:GC_AlfaAesar") == 0)
			NewDataFolder root:GC_AlfaAesar
		Endif
		Duplicate/O wave0, root:GC_AlfaAesar:gc_alfa_ref_q
		Duplicate/O wave1, root:GC_AlfaAesar:gc_alfa_ref_i
		Duplicate/O wave2, root:GC_AlfaAesar:gc_alfa_ref_s
		Killwaves/Z wave0, wave1, wave2
		Print "Calibration curve of glassy carbon has been loaded successfully in a datafolder :root:GC_AlfaAesar."
		Print "The data was measured at SPring8 BL03 and correctly normalized to absolute scale with a NIST glassy carbon standard SRM3600."
	Endif
	
	DoAlert 1, "Do you want to append the loaded GC profiles on the top graph?"
	If(V_flag == 1)
		wave xwave = XWaveRefFromTrace("",StringFromList(0,TraceNameList("",";",5)))
//		variable qOR2t = StringMatch(NameOfWave(xwave), "*_2t")  // q for 0, s for 1
//		qOR2t = 0 // 2021-05-04 currently, I did not have the procedure to create 2t wave for GC, which depends on wavelength.
		
		DFREF savDF = GetDataFolderDFR()
		SetDataFolder root:GC_AlfaAesar
		R2D_Display1D(1, "_q")  //1 indicates append
		SetDataFolder savDF
	Endif
	
End

Static Function/S FindAfile(target, ext)
	string target, ext
   
   string path
   variable recurse
   path = SpecialDirPath("Igor Pro User Files",0,0,0)
    
   recurse=1
    
   string fileList=""
   string files=""
   string pathName = "tmpPath"
   string folders =path+";"                                                    // Remember the full path of all folders in "path" & search each for "ext" files
   string fldr
    do
        fldr = stringFromList(0,folders)
        NewPath/O/Q $pathName, fldr                                             // sets S_path=$path, and creates the symbolic path needed for indexedFile()
        PathInfo $pathName
        files = indexedFile($pathName,-1,ext)                                   // get file names
        if (strlen(files))
            files = fldr+":"+ replaceString(";", removeEnding(files), ";"+fldr+":") // add the full path (folders 'fldr') to every file in the list
            fileList = addListItem(files,fileList)
        endif
        if (recurse)
            folders += indexedDir($pathName,-1,1)                               // get full folder paths
        endif
        folders = removeFromList(fldr, folders)                                 // Remove the folder we just looked at
    while (strlen(folders))	
 	
 	target = "*"+target+"*"
 	string outputpath = RemoveEnding(ListMatch(fileList, target), ";")
   return outputpath
End


Function AbsoluteNorm1D()

	//////ERROR CHECKER///////
	If(R2D_Error_1Dexist() == -1)
		Abort
	Elseif(R2D_Error_DatasheetExist1D() == -1)
		Abort
	Elseif(R2D_Error_DatasheetMatch1D() == -1)
		Abort
	Endif
	//////////////////////////

	///////////////TYPE A CORRECTION FACTOR///////////////
	Variable AbsFactor
	Prompt AbsFactor, "Reference x ? = This Time"		// Set prompt for x param
	DoPrompt "Enter correction factor", AbsFactor
	if (V_Flag)
		Print "User canceled"
		return -1								// User canceled
	Elseif(AbsFactor <= 0)
		Print "AbsFactor must be a positive value."
		return -1
	endif
			
	////////////DUPLICATE DATAFOLDER////////////////////	
	R2D_Unique1DDataFolder("a")

	/////////////////////NORMALIZATION//////////////////////
	string IntList = WaveList("*_i", ";","DIMS:1,TEXT:0") //return a list of int in current datafolder
	IntList = R2D_skip_fit(IntList)
	variable numOf1D = ItemsInList(IntList)
	wave/T Datasheet = ::Red2DPackage:Datasheet
	variable i
	String targetName
	For(i=0;i<numOf1D; i+=1)
		
		//Get target name from targetlist and remove the unncessary symbols.
		targetName = RemoveEnding(StringFromList(i, IntList), "_i")
		Wave Wave1D = $(targetName + "_i")
		Wave Wave1D_s = $(targetName + "_s")
		
		//Do the correction.
		Wave1D /= AbsFactor
		Wave1D_s /= AbsFactor
		
		Print NameOfWave(Wave1D) +"/"+ num2str(AbsFactor)
		Print NameOfWave(Wave1D_s) +"/"+ num2str(AbsFactor)
				
	Endfor
	
	Print "Absolute intensity correction completes..."
	
End


// *** Solvent subtraction
Function SolventSubtraction()

	//////ERROR CHECKER///////
	If(R2D_Error_1Dexist() == -1)
		Abort
	Elseif(R2D_Error_DatasheetExist1D() == -1)
		Abort
	Elseif(R2D_Error_DatasheetMatch1D() == -1)
		Abort
	Endif
	//////////////////////////
	
	Killwindow/Z SolventSubtractionPanel
	NewPanel/K=1/W=(100,100,500,250) as "Solvent subtraction"
	RenameWindow $S_name, SolventSubtractionPanel
	
	TitleBox WSPopupTitle1,pos={90,23},frame=0, fSize=14, title="Select a wave of solvent to subtract"
	Button SolventSelector,pos={30,55},size={345,23}, fSize=14
	MakeButtonIntoWSPopupButton("SolventSubtractionPanel", "SolventSelector", "SolventPopupWaveSelectorNotify", popupWidth = 400, popupHeight = 600, options=PopupWS_OptionFloat)
	PopupWS_MatchOptions("SolventSubtractionPanel", "SolventSelector", matchStr = "*i", listoptions = "DIMS:1,TEXT:0")
	PopupWS_SetPopupFont("SolventSubtractionPanel", "SolventSelector", fontsize = 13)
	///MakeButtonIntoWSPopupButton is a builtin function in Igor Pro.
	
	Variable/G ::Red2DPackage:U_SolvFrac
	SetVariable setvar0 value=::Red2DPackage:U_SolvFrac, fSize=14, limits={0,1,0.01}, pos={30,105}, size={200,23}, title="Solvent fraction"
	Button bt0,pos={275,103},size={100,23}, fSize=14, proc=SolventSubtractButtonProc,title="Subtract"	
	
End

Function SolventSubtractButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up

			/////////////////////////GET 1D WAVELIST TO NORMALIZE/////////////////////////
			String IntList = WaveList("*_i", ";","DIMS:1,TEXT:0") //return a list of int in current datafolder
			IntList = R2D_skip_fit(IntList)
			Variable numOf1D = itemsinlist(IntList)			
			
			//////////////////////////////GET SOLVENT WAVE////////////////////////////////
			String SolventPath = PopupWS_GetSelectionFullPath("SolventSubtractionPanel", "SolventSelector")
			If(cmpstr(SolventPath, "(no selection)", 0) == 0)
				Print "False"
				Abort "No selection."
			Endif
			Duplicate/FREE/O $SolventPath, refSolvent
			Duplicate/FREE/O $(RemoveEnding(SolventPath, "_i")+"_s"), refSolvent_s
			
			wave testwave = $(StringFromList(0, IntList))
			If(Dimsize(refSolvent,0)!=Dimsize(testwave,0))
				Print "False"
				Killwaves refSolvent, refSolvent_s
				Abort "The number of points in the selected buffer wave does not match that of 1D waves in current datafolder."
			Endif
			
			/// Duplicate datafolder to backup data before nomalization.
			R2D_Unique1DDataFolder("s")
			
			///////////////////////////SUBTRACT CELL////////////////////////////////
			String targetName
			NVAR SolvFrac = ::Red2DPackage:U_SolvFrac
			variable i
			For(i=0;i<numOf1D; i+=1)
				//Set reference of target wave in current folder. Only deal with waves having name in refname(Datasheet).

				targetName = RemoveEnding(StringFromList(i, IntList), "_i")
				Wave Wave1D = $(targetName + "_i")
				Wave Wave1D_s = $(targetName + "_s")
		
				Wave1D -= refSolvent * SolvFrac
				Wave1D_s = (Wave1D_s^2 + (refSolvent_s*SolvFrac)^2)^0.5
				
			Endfor
	
			Killwindow SolventSubtractionPanel
			Print SolventPath + "*"+ num2str(SolvFrac)
			Print "is subtracted from"
			Print IntList
			Print "Solvent subtraction completes..."
					
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

