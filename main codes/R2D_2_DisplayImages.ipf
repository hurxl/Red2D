#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/////////GUI//////////
Function R2D_Display2D()
	/// Check if in the image folder.
	String ImageFolderPath = R2D_GetImageFolderPath()
	If(strlen(ImageFolderPath) == 0)
		Abort "You may be in a wrong datafolder."
	Endif
	
	/// Check if panel exist
	DoWindow Display2D
	If(V_flag == 0)
		NewPanel/K=1/N=Display2D/W=(800,100,1557,650)
		SetWindow Display2D, hook(Display2D) = R2D_DisplayImagesWindowHook	
	Else
		DoWindow/F Display2D
	Endif
	
	// Create a popupmenu to select the order of ImageList and then create the Imagelist
	String savedDF = GetDataFolder(1)
	SetDataFolder $ImageFolderPath
	NewDataFolder/O Red2Dpackage
	Variable/G :Red2Dpackage:U_SortOrder
	NVAR SortOrder = :Red2Dpackage:U_SortOrder
	If(SortOrder == 0 || numtype(SortOrder) != 0)
		SortOrder = 1
	Endif
	
	// Color range
	Variable/G :Red2DPackage:U_ColorLow
	Variable/G :Red2DPackage:U_ColorLowStep
	Variable/G :Red2DPackage:U_ColorHigh
	Variable/G :Red2DPackage:U_ColorHighStep
	Variable/G :Red2DPackage:U_ColorLog
	NVAR lowstep = :Red2DPackage:U_ColorLowStep
	NVAR highstep = :Red2DPackage:U_ColorHighStep
	
	// Create an image list
	R2D_CreateImageList(SortOrder)  // 1 for name, 2 for date created
	Wave/T ImageList = :Red2DPackage:ImageList
	Make/O/T/N=0 :Red2DPackage:ImageNote
	
	//Create listbox named ImageList and make it follows ListBoxProc
	ListBox lb listWave=ImageList, mode=1, frame=4, size={350,320}, pos={5,25}, fSize=13, proc=ListBoxProcShow2D
	ListBox lb2 listWave=:Red2DPackage:ImageNote, mode=0, frame=4, size={400,520}, pos={355,25}, fSize=13

	TitleBox title0 title="Images",  fSize=14, pos={145,5}, frame=0
	TitleBox title1 title="Note",  fSize=14, pos={515,5}, frame=0

	// Sort
	PopupMenu popup0 title="Sort by ",value="Name;Date created",fSize=13, pos={40, 358}
	PopupMenu popup0 mode=SortOrder, proc=PopMenuProc_Diplay2D_SortOrder	

	// Bring to Front
	Button button0 title="Bring to Front", fSize=13, size={110,23},pos={200,355},proc=ButtonProcR2D_BringImageToFront

	// Color Range
	TitleBox title2 title="Color Adjust",  fSize=13, pos={40,415}, frame=0
	CheckBox cb1 title="log Color", pos={200, 415}, fSize=13, variable=:Red2DPackage:U_ColorLog, proc=R2D_LogColor_CheckProc
	SetVariable setvar0 title="Low",pos={40,445},size={120,25},limits={-inf,+inf, lowstep},fSize=13, value=:Red2DPackage:U_ColorLow, proc=R2D_ColorRange_SetVarProc
	SetVariable setvar2 title="High",pos={200,445},size={120,25},limits={-inf,+inf, highstep},fSize=13, value=:Red2DPackage:U_ColorHigh, proc=R2D_ColorRange_SetVarProc

	// Save Image
	Button button1 title="Export JPEG", fSize=13, size={110,23},pos={50,500},proc=ButtonProcR2D_SaveImageAsJPEG
	Checkbox cbox0 title="Use Sample Name", fSize=13, pos={180, 503}
	
	// Misc
	GroupBox group0 pos={30,395},size={300,2}
	GroupBox group1 pos={30,480},size={300,2}
//	GroupBox group2 pos={30,505},size={300,2}
	
	SetDataFolder $savedDF
End


Function ButtonProcR2D_BringImageToFront(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			DoWindow/F IntensityImage
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcR2D_SaveImageAsJPEG(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			String WinNameStr = "IntensityImage"
			Variable WhichName
			
			ControlInfo/W=Display2D cbox0
			If(V_Value == 0)
				WhichName = 0
			else
				WhichName = 1
			endif

			R2D_SavePic(WinNameStr, WhichName)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ListBoxProcShow2D(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	switch( lba.eventCode )
		case 4: // cell selection
			Variable numOfrows = DimSize(listWave,0)
			If(row < numOfrows)
				/// Check if in the image folder.
				String ImageFolderPath = R2D_GetImageFolderPath()
				If(strlen(ImageFolderPath) == 0)
					Abort "You may be in a wrong datafolder."
				Endif
				String savedDF = GetDataFolder(1)
				SetDataFolder $ImageFolderPath
				
				wave/T ImageList = :Red2DPackage:ImageList
				If(!WaveExists(ImageList))
					Abort "Imagelist does not exist. You may be in a wrong datafolder."
				Endif
				String currImageListPath = GetWavesDataFolder(ImageList, 2)
				String listboxImageListPath = GetWavesDataFolder(listWave, 2)
				If(cmpstr(currImageListPath, listboxImageListPath) != 0)
					R2D_Display2D()
					Abort "We refreshed the listbox. Try again."
				Endif
			
				Show2D(row)
				
				String ImageNote_content = note($ImageList[row]) // Get selected Imagename by using the flag row.
				wave/T tempnote = ListToTextWave(ImageNote_content, "\r")
				Duplicate/O/T tempnote, :Red2DPackage:ImageNote

				SetDataFolder $savedDF

			Endif
			break
	endswitch

	return 0
End

Function PopMenuProc_Diplay2D_SortOrder(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
//			Print popNum
			
			String ImageFolderPath = R2D_GetImageFolderPath()
			If(strlen(ImageFolderPath) == 0)
				Abort "You may be in a wrong datafolder."
			Endif
			String savedDF = GetDataFolder(1)
			SetDataFolder $ImageFolderPath
			
			NVAR SortOrder = :Red2DPackage:U_SortOrder
			SortOrder = popNum
			R2D_CreateImageList(SortOrder)  // 1 for name, 2 for date created
			
			SetDataFolder $savedDF

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function R2D_DisplayImagesWindowHook(s)
	STRUCT WMWinHookStruct &s
	
	Variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.

	switch(s.eventCode)
		case 0:	// window activated
			String ImageFolderPath = R2D_GetImageFolderPath()
			If(strlen(ImageFolderPath) > 0)
				R2D_Display2D()
//				Print "Image folder detected. Refresh list."
				hookResult = 1			
			Endif
			break		
	endswitch

	return hookResult	// If non-zero, we handled event and Igor will ignore it.
End

Function R2D_ColorRange_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			
			
			NVAR low = :Red2DPackage:U_ColorLow
			NVAR high = :Red2DPackage:U_ColorHigh
			NVAR lowstep = :Red2DPackage:U_ColorLowStep
			NVAR highstep = :Red2DPackage:U_ColorHighStep
			
			lowstep = 10^floor( (log(low)-1) )
			highstep = 10^floor( (log(high)-1) )
			
			if(numtype(lowstep)==2 || lowstep <= 0)
				lowstep = 1
			endif
			if(numtype(highstep)==2 || highstep <= 0)
				highstep = 1
			endif
			
			SetVariable setvar0 limits={-inf,+inf,lowstep}
			SetVariable setvar2 limits={-inf,+inf,highstep}

		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
			NVAR low = :Red2DPackage:U_ColorLow
			NVAR high = :Red2DPackage:U_ColorHigh

			R2D_ColorRangeAdjust_worker(low, high)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function R2D_LogColor_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			print checked
			Variable LogColor = checked
			ModifyImage ''#0 log=LogColor
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//////////Main Code////////////

Static Function Show2D(row)
	variable row
	
	/// Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and imagelist.
	wave/T ImageList = :Red2DPackage:ImageList // create a wave referece to a text wave "Z_ImageList"
	Variable NumInList = DimSize(ImageList,0) // Get items number in Imagelist

	NVAR low = :Red2DPackage:U_ColorLow
	NVAR high = :Red2DPackage:U_ColorHigh
	NVAR ColorLog = :Red2DPackage:U_ColorLog

	If(row>NumInList-1) // Check if selected row in range. If out of range do nothing.
		// Do nothing.
	Else
		String SelImageName = ImageList[row] // Get selected Imagename by using the flag row.
		
		DoWindow IntensityImage // Check if there is a window named 2DImageWindow. Exist returns 1 else 0.	
		If(V_flag == 0) // Create a new image window with name as 2DImageWindow if not exists.
			NewImage/K=1/N=IntensityImage $SelImageName
//			ModifyImage/W=IntensityImage $(SelImageName)	 ctab= {1,*,ColdWarm,0},log=1
			if(numtype(low) == 2 || numtype(high) == 2 || numtype(ColorLog) == 2)
				ModifyImage/W=IntensityImage $(SelImageName)	 ctab= {1,*,Turbo,0},log=1
			else
				ModifyImage/W=IntensityImage $(SelImageName)	 ctab= {low,high,Turbo,0},log=ColorLog
			endif
		Else // Replace selected images on the window named 2DImageWindow.
			String OldImage = ImageNameList("IntensityImage",";") // Get existing ImageName in the window ImageGraph
			ReplaceWave/W=IntensityImage image = $(StringFromList(0,OldImage)), $(SelImageName) //Replace images. image is a flag here	
		Endif
				
//		//Set cursor properties.
//		Cursor /M/C=(65535,65535,65535)/S=1 A
//		Cursor /M/C=(65535,65535,65535)/S=1 B
//		Cursor /M/C=(65535,65535,65535)/S=1 C
//		Cursor /M/C=(65535,65535,65535)/S=1 D
//		Cursor /M/C=(65535,65535,65535)/S=1 E
//		Cursor /M/C=(65535,65535,65535)/S=1 F
//		Cursor /M/C=(65535,65535,65535)/S=1 G
//		Cursor /M/C=(65535,65535,65535)/S=1 H
//		Cursor /M/C=(65535,65535,65535)/S=1 I
//		Cursor /M/C=(65535,65535,65535)/S=2 J
		
		DoWindow/F Display2D
				
	Endif
End

Function/S R2D_GetImageFolderPath()

	String ImageFolderPath = ""
	If(R2D_Error_ImagesExist(NoMessage = 1) == 0) // no error
		ImageFolderPath = GetDataFolder(1)
	Elseif(R2D_Error_1Dexist(NoMessage = 1) == 0) // no error
		ImageFolderPath = GetDataFolder(1)+":"
	Endif
	
	return ImageFolderPath

End


Function R2D_SavePic(WinNameStr, WhichName)
	String WinNameStr
	Variable WhichName
	
	// get image name
//	String WinNameStr = "IntensityImage"
	String TopImageName = StringFromList(0, ImageNameList(WinNameStr, ";"))
	
	// get sample name
	String PackagePath
	if(stringmatch(GetDataFolder(1), "root:"))
		PackagePath = "root:Red2Dpackage:"
	else
		PackagePath = GetDataFolder(1)+":Red2Dpackage:"
	endif
	Wave/T datasheet = $(PackagePath + "Datasheet")
	String SampleName
	If(WaveExists(datasheet)==1)
		Make/FREE/T/O/N=(DimSize(Datasheet,0)) ImageName = Datasheet[p][%ImageName]
		FindValue/TEXT=(TopImageName) ImageName  // get the index of the corresponding ImageName		
		If(V_value != -1) // if the imagename was found, use datasheet info. Otherwise, use defualt. V_value stores the index from FindValue	
			If(FindDimLabel(Datasheet, 1, "SampleName") != -2)  // if there is a column, SampleName, then use the datasheet info.  Otherwise, use defualt.
				SampleName = Datasheet[V_value][%SampleName]
			Endif
		Endif
	Endif

	// Set file name
	String filename
	Switch(WhichName)
		Case 1:
			If(Strlen(SampleName) == 0)	// if sample name does not exist, use image name
				filename = TopImageName
			Else
				filename = SampleName //	set file name
			Endif
			break
		
		default:
			filename = TopImageName //	set file name
			break
	Endswitch

	// save as a picture	
	Variable DPI = 600
	SavePICT/O/WIN=$WinNameStr/E=-6/RES=(DPI) as filename

End

Function R2D_ColorRangeAdjust_worker(low, high, [tarWinName])
	variable low
	variable high
	string tarWinName
	
	If(ParamIsDefault(tarWinName))
		ModifyImage ''#0 ctab= {low,high,Turbo,0}
	Else
		If(Strlen(WinList(tarWinName, ";","WIN:1"))>0)
			ModifyImage/W=tarWinName ''#0 ctab= {low,high,Turbo,0}
		Endif
	Endif

End