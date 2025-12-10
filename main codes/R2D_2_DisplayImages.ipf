#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// *** GUI
Function R2D_Display2D()

	/// Check if in the image folder.
	String ImageFolderPath = R2D_GetImageFolderPath()
	If(strlen(ImageFolderPath) == 0)
		Abort "You may be in a wrong datafolder."
	Else
		String savedDF = GetDataFolder(1)	// save current folder as a reference
		SetDataFolder $ImageFolderPath	// set datafolder to the image folder
		String simple_imagefolderpath = GetDataFolder(1)		// for display, the default image folder path may contain ::
		NewDataFolder/O Red2Dpackage	// create an Red2Dpackage folder within the image folder
	Endif
	
	/// Check if panel exist
	DoWindow Display2D
	If(V_flag == 0)
		NewPanel/K=1/N=Display2D/W=(800,100,1557,680)
		SetWindow Display2D, hook(Display2D) = R2D_DisplayImagesWindowHook	
	Else
		DoWindow/F Display2D
	Endif
	
	
	// Create a popupmenu to select the order of ImageList and then create the Imagelist
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
	if(numtype(lowstep)==2)
		lowstep = 0
	endif
	if(numtype(highstep)==2)
		highstep = 0
	endif
	
	// Color table
	String/G :Red2DPackage:U_ColorTable
	SVAR ColorTable = :Red2DPackage:U_ColorTable
	If (Strlen(ColorTable) == 0) // Use Turbo when a is not selected.
		ColorTable = "Turbo" 
	endif
	
	// Create an image list
	R2D_CreateImageList(SortOrder)  // 1 for name, 2 for date created
	Wave/T ImageList = :Red2DPackage:ImageList
	Wave/T/Z ImageNote = :Red2DPackage:ImageNote
	if(!WaveExists(ImageNote))
		Make/O/T/N=0 :Red2DPackage:ImageNote
	endif
	
	//Create listbox named ImageList and make it follows ListBoxProc
	ListBox lb listWave=ImageList, mode=1, frame=4, size={350,320}, pos={5,25}, fSize=13, proc=ListBoxProcShow2D
	ListBox lb2 listWave=ImageNote, mode=0, frame=4, size={400,550}, pos={355,25}, fSize=13, proc=R2D_ListBoxProc_Display2D_Note

	TitleBox title0 title=simple_imagefolderpath,  fSize=14, pos={6,5}, frame=0
	TitleBox title1 title="Note",  fSize=14, pos={515,5}, frame=0

	// Sort
	PopupMenu popup0 title="",value="Name;Date created",fSize=13, pos={240, 4}, bodyWidth=100
	PopupMenu popup0 mode=SortOrder, proc=PopMenuProc_Diplay2D_SortOrder	

	// Bring to Front
	Button button0 title="Bring to Front", fSize=13, size={110,23},pos={50,355},proc=ButtonProcR2D_BringImageToFront
	
	// Hide Mask
	Button button1 title="Hide Mask", fSize=13, size={110,23},pos={200,355},proc=ButtonProcR2D_HideMask

	// Color Range and Table
	TitleBox title2 title="Adjust Color",  fSize=13, pos={30,410}, frame=0
	CheckBox cb0 title="log Color", pos={130, 410}, fSize=13, variable=:Red2DPackage:U_ColorLog, proc=R2D_LogColor_CheckProc
	Button button5 title="Auto Color", fSize=13, size={90,23},pos={235,405},proc=BP_R2D_AutoColorImage
	SetVariable setvar0 title="Low",pos={30,445},size={130,25},limits={-inf,+inf, lowstep},fSize=13, value=:Red2DPackage:U_ColorLow, proc=R2D_ColorRange_SetVarProc
	SetVariable setvar1 title="High",pos={200,445},size={130,25},limits={-inf,+inf, highstep},fSize=13, value=:Red2DPackage:U_ColorHigh, proc=R2D_ColorRange_SetVarProc
	TitleBox title3 title="Color Table", fSize=13, pos={30,480}, frame=0
	PopupMenu popup1,mode=(WhichListItem(ColorTable, CTabList(),";")+1),value=#"\"*COLORTABLEPOPNONAMES*\"", pos={132,478},size={200,20},proc=Red2D_ColorTableMenu

	// Save Image
	TitleBox title4 title="Export as", fSize=13, pos={30,520}, frame=0
	Button button2 title="JPEG", fSize=13, size={50,23},pos={120,515},proc=ButtonProcR2D_SaveImageAsJPEG
	Button button3 title="PDF", fSize=13, size={50,23},pos={180,515},proc=ButtonProcR2D_SaveImageAsPDF
	Button button4 title="TIFF", fSize=13, size={50,23},pos={240,515},proc=ButtonProcR2D_SaveImageAsTIFF
	Checkbox cb1 title="Use Sample Name", fSize=13, pos={50, 550}
	Checkbox cb2 title="Export All", fSize=13, pos={220, 550}
	
	// Misc
	GroupBox group0 pos={30,390},size={300,2}
//	GroupBox group1 pos={30,510},size={300,2}
//	GroupBox group2 pos={30,505},size={300,2}
	
	SetDataFolder $savedDF
End

// *** Action
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

Function ButtonProcR2D_HideMask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
//			string masklist = R2D_GetMaskList_simple()
//			variable nitem = itemsInList(masklist)
//			variable i
//			string maskname
//			for(i=0; i<nitem; i++)
//				maskname = StringFromList(i, masklist)
//				RemoveImage/W=IntensityImage/Z $maskname
//			endfor

			string imglist = ImageNameList("IntensityImage",";")
			variable nitem = itemsInList(imglist)
			variable i
			string maskname
			for(i=nitem-1; i>0; i--)
				maskname = StringFromList(i, imglist)
				RemoveImage/W=IntensityImage/Z $maskname
			endfor
		
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function BP_R2D_AutoColorImage(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			
			DoWindow/F IntensityImage
			If(V_flag == 0)
				return -1	// image does not exist
			Endif
			
			String ImageFolderPath = R2D_GetImageFolderPath()	// Check if in the image folder
			If(strlen(ImageFolderPath) == 0)
				Abort "You may be in a wrong datafolder."
			Endif
			String savedDF = GetDataFolder(1)
			
			SetDataFolder $ImageFolderPath
			
			String TopImageName = StringFromList(0, ImageNameList("IntensityImage", ";"))
			wave imagew = $TopImageName
			
			MatrixOP/FREE/O hh = maxval(imagew)
			MatrixOP/FREE/O ll = minval(imagew)
			
			NVAR low = :Red2DPackage:U_ColorLow
			NVAR high = :Red2DPackage:U_ColorHigh
			low = ll[0]
			high = hh[0]
			
			low = 0.1*high	// this makes the image looks better than using real low value
			
			R2D_ColorRangeAdjust_worker(low, high)
		
			SetDataFolder $savedDF
			
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

			R2D_SavePic("IntensityImage", ".jpg")
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcR2D_SaveImageAsPDF(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			R2D_SavePic("IntensityImage", ".pdf")
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcR2D_SaveImageAsTIFF(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			R2D_SavePic("IntensityImage", ".tif")
			
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
		case 1: // Mouse down
			if (lba.eventMod & 0x10)// Right-click?
				R2D_Display2D_WaveListRightClick(row, listwave)
			endif
			break
	
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
				ImageNote_content = ReplaceString("\r\n", ImageNote_content, "\r")
				ImageNote_content = ReplaceString("\n", ImageNote_content, "\r")
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
//			String ImageFolderPath = R2D_GetImageFolderPath()
//			If(strlen(ImageFolderPath) > 0)
				R2D_Display2D()
//				Print "Image folder detected. Refresh list."
				hookResult = 1			
//			Endif
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
			
			if(numtype(lowstep)==2)
				lowstep = 1
			endif
			if(numtype(highstep)==2)
				highstep = 100
			endif
			
			SetVariable setvar0 limits={-inf,+inf,lowstep}
			SetVariable setvar1 limits={-inf,+inf,highstep}

		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
			NVAR low = :Red2DPackage:U_ColorLow
			NVAR high = :Red2DPackage:U_ColorHigh
			
			DoWindow IntensityImage
			If(V_flag != 0)
				R2D_ColorRangeAdjust_worker(low, high)
			Endif
			
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
			Variable LogColor = checked
			ModifyImage ''#0 log=LogColor
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function Red2D_ColorTableMenu(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			SVAR ColorTable = :Red2DPackage:U_ColorTable
			ColorTable = popStr
			NVAR low = :Red2DPackage:U_ColorLow
			NVAR high = :Red2DPackage:U_ColorHigh
			
			DoWindow IntensityImage
			If(V_flag != 0)
				R2D_ColorRangeAdjust_worker(low, high)
			Endif
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function R2D_ListBoxProc_Display2D_Note(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	
	switch (lba.eventCode)
	case 1: // Mouse down
		if (lba.eventMod & 0x10)// Right-click?
			R2D_Display2D_NoteRightClick(row, listwave)
		endif
		break
	endswitch

	return 0

End

static Function R2D_Display2D_WaveListRightClick(row, listwave)
	variable row
	wave/T listwave

	String popupItems = ""
	popupItems += "Copy;"
	PopupContextualMenu popupItems
	
	string tocopy = ""
	string s
	strswitch (S_selection)
		case "Copy":
			tocopy = listWave[row]
			break
	endswitch
	
	PutScrapText tocopy
	
	return 0
End

static Function R2D_Display2D_NoteRightClick(row, listwave)
	variable row
	wave/T listwave

	String popupItems = ""
	popupItems += "Copy Value;Copy Number;Copy Row;Copy Entire Note;"
	PopupContextualMenu popupItems

	string tocopy = ""
	string s
	strswitch (S_selection)
		case "Copy Value":
			s = StringFromList(1, listWave[row], ":")
			s = TrimString(s)
			s = ReplaceString("\"",s,"")
			tocopy = s
			break
		case "Copy Number":	
			s = StringFromList(1, listWave[row], ":")
			s = TrimString(s)
			s = ReplaceString("\"",s,"")
			variable val = str2num(s)	// remove non-numeric characters
			s = num2str(val)
			tocopy = s
			break
		case "Copy Row":
			tocopy = listWave[row]
			break
		case "Copy Entire Note":
			for(s: listWave)
				tocopy += s + "\r"
			endfor			
			break
	endswitch
	
	PutScrapText tocopy
	
	return 0
End


// *** Main Code
Static Function Show2D(row)
	variable row
	
	/// Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and imagelist.
	wave/T ImageList = :Red2DPackage:ImageList // create a wave referece to a text wave "Z_ImageList"
	Variable NumInList = DimSize(ImageList,0) // Get items number in Imagelist

	NVAR low = :Red2DPackage:U_ColorLow
	NVAR high = :Red2DPackage:U_ColorHigh
	NVAR ColorLog = :Red2DPackage:U_ColorLog
	SVAR ColorTable = :Red2DPackage:U_ColorTable

	If(row>NumInList-1) // Check if selected row in range. If out of range do nothing.
		// Do nothing.
	Else
	
	If (Strlen(ColorTable) == 0) // Use Turbo when a is not selected.
		ColorTable = "Turbo" 
	endif
		String SelImageName = ImageList[row] // Get selected Imagename by using the flag row.
		
		DoWindow IntensityImage // Check if there is a window named 2DImageWindow. Exist returns 1 else 0.	
		If(V_flag == 0) // Create a new image window with name as 2DImageWindow if not exists.
			NewImage/K=1/N=IntensityImage $SelImageName
//			ModifyImage/W=IntensityImage $(SelImageName)	 ctab= {1,*,ColdWarm,0},log=1
			if(numtype(low) == 2 || numtype(high) == 2 || numtype(ColorLog) == 2)
				ModifyImage/W=IntensityImage $(SelImageName)	 ctab= {1,*,$ColorTable,0},log=1
				low = 1
				high = wavemax($SelImageName)
				ColorLog = 1
			elseif(low == 0 && high == 0)
				ModifyImage/W=IntensityImage $(SelImageName)	 ctab= {1,*,$ColorTable,0},log=1
				low = 1
				high = wavemax($SelImageName)
				ColorLog = 1
			else
				ModifyImage/W=IntensityImage $(SelImageName)	 ctab= {low,high,$ColorTable,0},log=ColorLog
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




Function R2D_SavePIC(WinNameStr, extension)
	String WinNameStr
	String extension
	
	ControlInfo/W=Display2D cb1	// use sample name ?
	Variable WhichName
	If(V_Value == 0)
		WhichName = 0
	else
		WhichName = 1
	endif
	
	ControlInfo/W=Display2D cb2 // export all ?
	If(V_Value == 0)	// export only top image
		R2D_SavePIC_worker(WinNameStr, WhichName, extension)
	else	// export all
		R2D_Display2D() // refresh list
		
		String ImageFolderPath = R2D_GetImageFolderPath()	// Check if in the image folder
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
			variable NumOfImages = numpnts(ImageList)
			
			NewPath/O ForlderToSaveImage
			variable i
			for(i=0; i<NumOfImages; i++)
				Show2D(i)
				R2D_SavePIC_worker(WinNameStr, WhichName, extension, pathName = "ForlderToSaveImage")
				
				String ImageNote_content = note($ImageList[i]) // Get selected Imagename by using the flag row.
				wave/T tempnote = ListToTextWave(ImageNote_content, "\r")
				Duplicate/O/T tempnote, :Red2DPackage:ImageNote
			endfor		
		SetDataFolder $savedDF
	endif

End


Function R2D_SavePIC_worker(WinNameStr, WhichName, extension, [pathName])
	String WinNameStr
	Variable WhichName
	String extension
	String pathName		// name of symbolic path for the folder to save files
	
	// get image name
	String TopImageName = StringFromList(0, ImageNameList(WinNameStr, ";"))
	
	// get sample name
	String PackagePath
	if(stringmatch(GetDataFolder(1), "root:"))
		PackagePath = "root:Red2Dpackage:"
	else
		PackagePath = GetDataFolder(1)+"Red2Dpackage:"
	endif
	Wave/Z/T datasheet = $(PackagePath + "Datasheet")
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
			If(Strlen(SampleName) > 0 )	// if sample name exist
				filename = SampleName //	set file name
			Else
				filename = TopImageName
			Endif
			break
		
		default:
			filename = TopImageName //	set file name
			break
	Endswitch
	filename += extension

	// save as a picture	
	if(stringmatch(extension, ".pdf"))
		if(ParamIsDefault(PathName))
			SavePICT/O/WIN=$WinNameStr/E=-2 as filename
		else
			SavePICT/O/WIN=$WinNameStr/E=-2/P=$pathName as filename
		endif
	elseif(stringmatch(extension, ".jpg"))
		if(ParamIsDefault(PathName))
			SavePICT/O/WIN=$WinNameStr/E=-6/RES=600 as filename
		else
			SavePICT/O/WIN=$WinNameStr/E=-6/RES=600/P=$pathName as filename
		endif
	elseif(stringmatch(extension, ".tif"))
		wave imagew = $TopImageName
//		R2D_convertWavenote2tiffTag(imagew)	// not work yet 2025-01-17
		wave/T TiffTag
		if(ParamIsDefault(PathName))
//			ImageSave/O/T="tiff"/DS=32/WT=TiffTag imagew as filename	// tag not work yet
			ImageSave/O/T="tiff"/DS=32 imagew as filename
		else
//			ImageSave/O/T="tiff"/DS=32/WT=TiffTag/P=$pathName imagew as filename	// tag not work yet
			ImageSave/O/T="tiff"/DS=32/P=$pathName imagew as filename
		endif
		KillWaves/Z TiffTag
	endif

End

Function R2D_ColorRangeAdjust_worker(low, high, [tarWinName])
	variable low
	variable high
	string tarWinName
	SVAR ColorTable = :Red2DPackage:U_ColorTable
	
	If(ParamIsDefault(tarWinName))
		ModifyImage ''#0 ctab= {low,high,$ColorTable,0}
	Else
		If(Strlen(WinList(tarWinName, ";","WIN:1"))>0)
			ModifyImage/W=tarWinName ''#0 ctab= {low,high,$ColorTable,0}
		Endif
	Endif

End


// *** MISC
Function/S R2D_GetImageFolderPath()

	String ImageFolderPath = ""
	If(R2D_Error_ImagesExist(NoMessage = 1) == 0) // no error
		ImageFolderPath = GetDataFolder(1)
	Elseif(R2D_Error_1Dexist(NoMessage = 1) == 0) // no error
		ImageFolderPath = GetDataFolder(1)+":"
	Endif
	
	return ImageFolderPath

End

Function R2D_convertWavenote2tiffTag(w)
	wave w
	
	string wnote = note(w)
	
	variable NumOfTag = ItemsInList(wnote, "\r")
	
	Make/T/O/N=(NumOfTag,5) TiffTag
	
	string tagi
	string key
	string val
	variable i
	for(i=0; i<NumOfTag; i++)
		
		// get key and val
		tagi = StringFromList(i,wnote, "\r")
		key = StringFromList(0, tagi, " : ")
		val = StringFromList(1, tagi, " : ")
		
		// write to tag wave 
		TiffTag[i][0] = num2str(40000 + i)	// ID		
		TiffTag[i][1] = key	// Description
		TiffTag[i][2] = num2str(2)	// Type, 4 = LONG (32-bit unsigned integer)
		TiffTag[i][3] = num2str(1)	// Length, The number of data elements stored in this tag
		TiffTag[i][4] = val	// Value
		
	endfor

End