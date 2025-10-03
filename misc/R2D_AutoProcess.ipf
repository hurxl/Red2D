#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// Auto import images and csv files from selected directory to a selected datafolder
// Opt applying mask in the selected datafolder
// Auto perform circular average in selected datafolder
// Auto perform normalization in the selected datafolder


/////////////////////////////////////////////////////////////////
//////////////////////////////GUI////////////////////////////////
/////////////////////////////////////////////////////////////////

Function R2D_AutoProcess_panel()

	// Check if panel exist
	DoWindow AutoProcess
	If(V_flag == 0)
		NewPanel/K=1/N=AutoProcess/W=(200,200,1020,520)
		SetDrawEnv fstyle= 0,fsize= 15, textrgb= (52428,1,20971), textxjust= 1
		DrawText 400,200,"\\sb+20CAUTION!"
		SetDrawEnv fstyle= 0,fsize= 15, textrgb= (52428,1,20971), textxjust= 1
		DrawText 400,220,"\\sb+20Fill beam center and SDD with 'Fit Standard' panel before starting the auto-process."
		SetDrawEnv fstyle= 0,fsize= 15, textrgb= (52428,1,20971), textxjust= 1
		DrawText 400,240,"\\sb+20These parameters need to be filled in the same datafolder you typed above."
	Else
		DoWindow/F AutoProcess
	Endif
	
	NewDataFolder/O root:Red2DPackage
	
	// set global strings and variables
	String/G root:Red2DPackage:pc_image_folder_path
	SVAR pc_image_folder_path = root:Red2DPackage:pc_image_folder_path
	String/G root:Red2DPackage:pc_datasheet_path
	SVAR pc_datasheet_path = root:Red2DPackage:pc_datasheet_path
	String/G root:Red2DPackage:image_df_path
	SVAR image_df_path = root:Red2DPackage:image_df_path
	String/G root:Red2DPackage:U_MaskName_Auto
	SVAR U_MaskName_Auto = root:Red2DPackage:U_MaskName_Auto
	String/G root:Red2DPackage:U_ImageExtension
	SVAR ImageExtension = root:Red2DPackage:U_ImageExtension
	
	// set panel objects
	variable selectionIndex
	SetVariable setvar0 title="Image Folder Path (PC)", value=pc_image_folder_path
	SetVariable setvar0 pos={20,20},size={700,50}, fSize=13, noedit=1, valueBackColor=(62300,62300,62300)
	SetVariable setvar1 title="Datasheet Path (PC)    ", value=pc_datasheet_path
	SetVariable setvar1 pos={20,50},size={700,50}, fSize=13, noedit=1, valueBackColor=(62300,62300,62300)
	SetVariable setvar2 title="Datafolder Path (Igor)  ", pos={20,80},size={580,50}, fSize=13
	SetVariable setvar2 value=image_df_path, proc=SetVarProc_ImageFolderPath
	Button button0 title="Browse", fSize=14, size={70,22},pos={730,18}, proc=ButtonProc_R2DAP_BrowseImagePath
	Button button1 title="Browse", fSize=14, size={70,22},pos={730,48}, proc=ButtonProc_R2DAP_BrowseDatasheetPath
	Button button2 title="Refresh Panel", fSize=14, size={110,23},pos={670,270},proc=ButtonProc_R2DAP_Refresh
	Button button3 title="Auto Process", fSize=20, fstyle=1, size={200,50}, valueColor=(52428,1,20971), pos={300,250},proc=ButtonProc_R2DAP_autoprocess
	TitleBox title0 title="<- Type by yourself",frame=0,fSize=13,pos={600,80}
	PopupMenu popup0 title="Image Extension            ", pos={20, 110}, fSize=13, value=".tif;.edf;.txt;.asc;.dat;", proc=ButtonProc_R2DAP_selectExtension
	ControlInfo/W=AutoProcess popup0
	if(cmpstr(S_Value, ImageExtension) != 0)	// if U_ImageExtension does not match the selected text.
		PopupMenu popup0 mode=1	// mode = 1 selects first item, i.e. .tif.
		ImageExtension = ".tif"	// forcely input ".tif" to U_ImageExtension
	endif
	PopupMenu popup1 title="Mask for Images            ", pos={20, 140}, fSize=13, value=R2D_GetMaskList_autoprocess(), proc=PopMenuProc_R2D_setautomask
	ControlInfo/W=AutoProcess popup1
//	if(strlen(R2D_GetMaskList_autoprocess())<9)	// if only 'no mask' is in the selection
	if(cmpstr(S_Value, U_MaskName_Auto) != 0)	// if selected mask does not match U_MaskName_Auto
		PopupMenu popup1 mode=1	// mode = 1 selects first item
		U_MaskName_Auto = "no mask"	// forcely input "no mask" to U_MaskName_Auto
//	else	// if mask wave exists
//		PopupMenu popup1
	endif
//	Execute/P/Q "PopupMenu popup1 pos={20, 140}"  // a workaround about Igor's know bug for bodywidth option.

End


/////////////////////////////////////////////////////////////////
///////////////////////////Main Codes////////////////////////////
/////////////////////////////////////////////////////////////////

// Get the mask list in a specified image datafolder.
Function/S R2D_GetMaskList_autoprocess()
	SVAR image_df_path = root:Red2DPackage:image_df_path
	
	If(cmpstr(image_df_path, "root") == 0 || cmpstr(image_df_path, "root:") == 0 )
		image_df_path = "root:"
	Endif
	
	string masklist = "no mask;"
	if(DataFolderExists(image_df_path))
		string maskfolder_path = RemoveEnding(image_df_path, ":") + ":Red2DPackage:Mask"	// user may add or not add ":"
		if(DataFolderExists(maskfolder_path))
			masklist = "no mask;" + WaveList("*", ";", "DIMS:2,TEXT:0", $maskfolder_path)
		endif
	endif
	
	return masklist
End

// Auto process main codes
Function R2D_AutoProcess()
	
	Print "\r"
	Print "**********************"
	Print "AUTO PROCESS STARTS..."
	/// Set datafolder to a predefined datafolder, which will be the main datafolder of this procedure.
	SVAR image_df_path = root:Red2DPackage:image_df_path  // Load the path of the user selected datafolder
	If(cmpstr(image_df_path, "root") == 0 || cmpstr(image_df_path, "root:") == 0 )
		image_df_path = "root:"
		SetDataFolder root:
	Else
		NewDataFolder/O/S $(RemoveEnding(image_df_path, ":"))  //Create a datafolder if not exist and set current datafolder there
	Endif
	DFREF HomeDFR = GetDataFolderDFR()  //save current folder as home reference
	NewDataFolder/O :Red2DPackage  // just in case
	NewDataFolder/O :Iq1D0TT  // just in case
	
	
	/// Load new images from predefined path
	SVAR pc_image_folder_path = root:Red2DPackage:pc_image_folder_path  // call predefined path
	SVAR ImageExtension = root:Red2DPackage:U_ImageExtension
//	R2D_LoadAllTIFF(path = pc_image_folder_path, overwrite = 0)  // load images. images already exists will be skipped.
	R2D_LoadImages(ImageExtension, "folder", 0, folderPath = pc_image_folder_path)
	SVAR ImageList = :Red2DPackage:U_ImageList  // U_imagelist is a global string created when loading images.
	// A note for imagelsit @2021-04-15
	// There are two version of imagelist; one is textwave "ImageList", and the other is string "U_ImageList".
	// You cannot call the textwave version and string version of the imagelist at the same time.
	// In this function I call the string version imagelist.
	// The best idea is to completely replace the ImageList textwave with the ImageList string.
	// However, because imagelist textwave is deeply involved in R2D package and I do not plan to replace it for now.
	
	/// Load datasheet from predefined path
	SVAR pc_datasheet_path = root:Red2DPackage:pc_datasheet_path  // call predefined path
	R2D_ImportDatasheet(path = pc_datasheet_path)  // load datasheet for all images.
	
	/// Create an imagelist containing nonreduced images. Use Iq1DoTT as the reference.
	Print "Finding non-reduced images..."
	string RedTraceList = ""
	string RedImageList = ""
//	string NonRedTraceList = ""
	string NonRedImageList = ""
	SetDataFolder :Iq1D0TT	// get reduced trace and image list from Iq1D0TT folder
		RedTraceList = Wavelist("*_i",";","DIMS:1,TEXT:0")
		RedImageList = ReplaceString("_i;", RedTraceList, ";")  // remove the suffix "_i" from each entry in the list
	SetDataFolder HomeDFR
	NonRedImageList = RemoveFromList(RedImageList, ImageList)	// Create a non reduced imagelist
//	NonRedTraceList = ReplaceString(";", NonRedImageList, "_i;")  // add the suffix "_i" to each entry in the list
	
	// refine the list if the corresponding time or trans is empty
	wave/T temp_datasheet = :Red2DPackage:Datasheet
	variable numOfdata = DimSize(temp_datasheet, 0)
	variable tim, trans
	string wn
	variable i
	For(i=0; i<numOfdata; i++)
		tim = str2num(temp_datasheet[i][%Time_s])
		trans = str2num(temp_datasheet[i][%Trans])
		if(numType(tim) == 2 ||numType(trans) == 2)
			wn = temp_datasheet[i][%ImageName]
			NonRedImageList = RemoveFromList(wn, NonRedImageList)
			Print wn, "does not have time or transmission value. Reudction skiped."
		endif
	Endfor

	/// Abort the procedure if there is no NonRedImage
	variable num_NonRedImage = itemsInList(NonRedImageList)
	If(num_NonRedImage == 0)
		Print "No proper image found."
		Print "AUTO PROCESS COMPLETES"
		Print " "
		return 0
	Else
//		Print "Try to recuding following images:"
		Print NonRedImageList
//		Print "Prepare to reduce these images..."
	Endif
	
	/// Copy non-reduced images to working folder "root:R2D_NonRedImages". This folder will be deleted at the end of this procedure.
	/// In this precedure, I decided to reduce all the "non-reduced" images instead of reducing only the "newly-loaded" images.
	NewDataFolder/O root:R2D_NonRedImages
	string NonRedImage_name, tempImageName
	For(i=0; i<num_NonRedImage ;i++)
		NonRedImage_name = StringFromList(i, NonRedImageList)
		tempImageName = "root:R2D_NonRedImages:"+NonRedImage_name
		Duplicate/O $NonRedImage_name, $tempImageName
	Endfor
	
	/// Copy Red2DPackage to the working folder ":Red2DPackage:R2D_NonRedImages" and set datafolder there.
	/// Red2DPackage contains the parameters for circular average.
	DuplicateDataFolder/O=2 :Red2DPackage, root:R2D_NonRedImages:Red2DPackage  // O=2 overwrites objects
	SetDataFolder root:R2D_NonRedImages  // movet to the working folder
	R2D_CreateImageList(2)  // create/refresh ImageList, which is a list of full images in current datafolder. necessary for DoCircular...	
	
	/// Get selected mask path
	SVAR U_MaskName_Auto = root:Red2DPackage:U_MaskName_Auto	// selected mask_name is stored in this global string
	string mask_path = RemoveEnding(image_df_path, ":") + ":Red2DPackage:Mask:" +	U_MaskName_Auto // Use "RemoveEnding" because user may add or not add ":"
	if(WaveExists($mask_path))
		Print mask_path + " will be applied to all images."
	else
		Print "User selected 'no mask' or the selected mask wave was not found. No mask will be applied."
	endif
	
	/// Do circular average for the nonreduced images, mask will be applied if selected
	InitiateCircularAverage(mask_path=mask_path)  // the output 1D files are stored in a folder named "Iq1D0", parameter 1 means mode 1 (auto mask mode)
	
	/// Normalize 1D
	R2D_ImportDatasheet(path = pc_datasheet_path, noedit = 1) // re-import datasheet to prevent datasheet not match problem.
	// disabled reimport datasheet because it may import new Trans and time values, while it was not there when filtering the images.
//	KillWindow/Z $WinName(0,2)  // kill the top-most table to enable delete folder. Top-most table should be the datasheet created above.
	R2D_TimeAndTrans1D()
	
//	// Remove Iq profiles with empty time and transmittance cells
//	wave/T temp_datasheet = ::Red2DPackage:Datasheet
//	numOfdata = DimSize(temp_datasheet, 0)
//	variable tim, trans
//	string ww
//	For(i=0; i<numOfdata; i++)
//		tim = str2num(temp_datasheet[i][%Time_s])
//		trans = str2num(temp_datasheet[i][%Trans])
//		if(numType(tim) == 2 || numType(trans) == 2)
//			wn = temp_datasheet[i][%ImageName]
//			Killwaves $(wn+"_q"), $(wn+"_i"), $(wn+"_s"), $(wn+"_2t")
//		endif
//	Endfor
//	Print "I_q profiles with empty time and transmittance cells were removed."
	String NewIq_list = WaveList("*_i", ";","DIMS:1,TEXT:0")
//	If(strlen(NewIq_list) == 0)
//		Print "No I_q profiles were found."
//	Else
//		Print "Newly reduced images are:"
//		Print NewIq_list
//	Endif
	
	/// Duplicate all the new 1D files to the main datafolder
	SetDataFolder HomeDFR
//	If(strlen(NewIq_list) != 0)
		DuplicateDataFolder/O=2 root:R2D_NonRedImages:Iq1D0TT, Iq1D0TT
//	Endif
	SetDataFolder Iq1D0TT
	
	/// Display 1D
	string windowName = "auto1D_TT"
	DoWindow/F $windowName
	If(strlen(NewIq_list) != 0)
		If(V_flag == 0)  // if speficied window does not exist
			R2D_Display1D(0, "_q", winNam=windowName)  // (0, 0, winNam) = (new graph, x scale = q, windowName)
		Else // if the specified window exists
			/// Append the newly reduced data
			R2D_Display1D(1, "_q", winNam=windowName, IntList=NewIq_list)  // (1, 0, winNam) = (append, x scale = q, windowName, tracelist)
		Endif
	Endif
	Print "New 1D profiles were appended to Auto1D_TT graph."
	
	/// Kill the working datafolder
	
	KillDataFolder/Z root:R2D_NonRedImages
	
	DoWindow/F AutoProcess
	
	Print "AUTO PROCESS COMPLETES..."
	
End


/////////////////////////////////////////////////////////////////
////////////////////////Button Actions///////////////////////////
/////////////////////////////////////////////////////////////////

Function ButtonProc_R2DAP_BrowseImagePath(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here

			NewPath/O R2D_PCImageFolder  // create a path
			PathInfo/S R2D_PCImageFolder  // to inform user
			SVAR pc_image_folder_path = root:Red2DPackage:pc_image_folder_path  // to inform user
			pc_image_folder_path = S_path  // to inform user
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ButtonProc_R2DAP_BrowseDatasheetPath(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			Variable refNum
			String filters = "Excel Files (*.xls,*.xlsx,*.xlsm):.xls,.xlsx,.xlsm;"
			filters += "All Files:.*;"
			Open/D/R/F=filters refNum  // display a dialog, file is read-only.
			if (strlen(S_fileName) == 0)		// User canceled?
				Print "User canceled"
				return 0
			endif
			SVAR pc_datasheet_path = root:Red2DPackage:pc_datasheet_path
			pc_datasheet_path = S_fileName		
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ButtonProc_R2DAP_Refresh(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			R2D_AutoProcess_panel()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ButtonProc_R2DAP_autoprocess(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			SVAR pc_image_folder_path = root:Red2DPackage:pc_image_folder_path
			SVAR pc_datasheet_path = root:Red2DPackage:pc_datasheet_path
			SVAR image_df_path = root:Red2DPackage:image_df_path
			
			GetFileFolderInfo/Z/Q pc_image_folder_path
			variable imgf_exist = V_flag
			
			GetFileFolderInfo/Z/Q pc_datasheet_path
			variable ds_exist = V_flag
			
			variable df_exist = DataFolderExists(image_df_path)
			string ca_evidence_path = RemoveEnding(image_df_path, ":") + ":Red2DPackage:centerX"
//			Print "df_exist = ", df_exist
			
			If(imgf_exist != 0)  // if any of the path does not exist
				Print "Specified image folder (PC) does not exist. Please check your path."
				Abort "Specified image folder (PC) does not exist.  Please check your path."
			Elseif(ds_exist != 0)
				Print "Specified datasheet (PC) does not exist. Please check your path."
				Abort "Specified datasheet (PC) does not exist.  Please check your path."
			Elseif(df_exist != 1 || strlen(image_df_path) == 0)
				Print "Specified datafolder (Igor) does not exist. Please check your path. If you select root, type root:."
				Abort "Specified datafolder (Igor) does not exist.  Please check your path.  If you select root,  type root:."
			Elseif(!WaveExists($ca_evidence_path))
				Print "You need to fit a standard sample in the datafolder that you specified."
				Abort "You need to fit a standard sample in the datafolder that you specified."
			Endif
			
			
			R2D_AutoProcess()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function SetVarProc_ImageFolderPath(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			SVAR U_MaskName_Auto = root:Red2DPackage:U_MaskName_Auto
			PopupMenu popup1, win=AutoProcess, mode=1, value=R2D_GetMaskList_autoprocess()
			U_MaskName_Auto = "no mask"
				
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_R2DAP_selectExtension(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			SVAR ImageExtension = root:Red2DPackage:U_ImageExtension
			ImageExtension = popStr
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function PopMenuProc_R2D_setautomask(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			SVAR U_MaskName_Auto = root:Red2DPackage:U_MaskName_Auto
			U_MaskName_Auto = popStr
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End