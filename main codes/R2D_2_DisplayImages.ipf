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
		NewPanel/K=1/N=Display2D/W=(800,100,1557,730)
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
	
	// Create a datafolder for custom LUT
	NewDataFolder/O root:Packages:ColorTables

	
	// Color range
	Variable/G :Red2DPackage:U_ColorLow
	Variable/G :Red2DPackage:U_ColorLowStep
	Variable/G :Red2DPackage:U_ColorHigh
	Variable/G :Red2DPackage:U_ColorHighStep
	Variable/G :Red2DPackage:U_LogColor
	Variable/G :Red2DPackage:U_reverseColor
	NVAR lowstep = :Red2DPackage:U_ColorLowStep
	NVAR highstep = :Red2DPackage:U_ColorHighStep
	if(numtype(lowstep)==2)
		lowstep = 0
	endif
	if(numtype(highstep)==2)
		highstep = 0
	endif
	
	// Built-in Color table
	String/G :Red2DPackage:U_BuiltinColorTable
	SVAR BuiltinColorTable = :Red2DPackage:U_BuiltinColorTable
	If (Strlen(BuiltinColorTable) == 0) // Use Turbo when a is not selected.
		BuiltinColorTable = "Turbo" 
	endif
	
	// Custom Color table
	String/G :Red2DPackage:U_CustomColorTable
	SVAR CustomColorTable = :Red2DPackage:U_CustomColorTable
	If (Strlen(CustomColorTable) == 0) // Use Turbo when a is not selected.
		CustomColorTable = "" 
	endif
	
	// Effective Color table
	String/G :Red2DPackage:U_ColorTable
//	SVAR ColorTable = :Red2DPackage:U_ColorTable
//	If (Strlen(ColorTable) == 0) // Use Turbo when a is not selected.
//		ColorTable = "Turbo" 
//	endif
	
	// Create an image list
	R2D_CreateImageList(SortOrder)  // 1 for name, 2 for date created
	Wave/T ImageList = :Red2DPackage:ImageList
	Wave/T/Z ImageNote = :Red2DPackage:ImageNote
	if(!WaveExists(ImageNote))
		Make/O/T/N=0 :Red2DPackage:ImageNote
	endif
	
	//Create listbox named ImageList and make it follows ListBoxProc
	ListBox lb listWave=ImageList, mode=1, frame=4, size={350,320}, pos={5,25}, fSize=13, proc=ListBoxProcShow2D
	ListBox lb2 listWave=ImageNote, mode=0, frame=4, size={400,600}, pos={355,25}, fSize=13, proc=R2D_ListBoxProc_Display2D_Note

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
//	TitleBox title2 title="Adjust Color",  fSize=13, pos={30,410}, frame=0
	SetVariable setvar0 title="Low",pos={30,445},size={130,25},limits={-inf,+inf, lowstep},fSize=13, value=:Red2DPackage:U_ColorLow, proc=R2D_ColorRange_SetVarProc
	SetVariable setvar1 title="High",pos={200,445},size={130,25},limits={-inf,+inf, highstep},fSize=13, value=:Red2DPackage:U_ColorHigh, proc=R2D_ColorRange_SetVarProc
	CheckBox cb0 title="log Color", pos={150, 410}, fSize=13, variable=:Red2DPackage:U_LogColor, proc=R2D_LogColor_CheckProc
	CheckBox cb4 title="Reverse Color", pos={30, 410}, fSize=13, variable=:Red2DPackage:U_reverseColor, proc=R2D_ReverseColor_CheckProc
	Button button5 title="Auto Color", fSize=13, size={90,23},pos={235,405},proc=BP_R2D_AutoColorImage

	TitleBox title3 title="Built-in Color", fSize=13, pos={30,484}, frame=0
	PopupMenu popup1, mode=(WhichListItem(BuiltinColorTable, CTabList(),";")+1), value=#"\"*COLORTABLEPOPNONAMES*\"", pos={132,482}, size={200,20}, proc=R2D_SelectBuiltinColor_PopProc

	TitleBox title4 title="Custom LUT", fSize=13, pos={30,518}, frame=0
	PopupMenu popup2, mode=(WhichListItem(CustomColorTable, R2D_RecursiveGetLUTList(root:Packages:ColorTables, 2, 1),";")+1)
	PopupMenu popup2, value=R2D_RecursiveGetLUTList(root:Packages:ColorTables, 2, 1)
	PopupMenu popup2, pos={132,515},size={200,20}, proc=R2D_SelectCustomColor_PopProc
	Checkbox cb3, title="", fSize=13, pos={110, 517}, proc=R2D_CustomColor_CheckProc
	

	// Save Image
	TitleBox title5 title="Export as", fSize=13, pos={30,560}, frame=0
	Button button2 title="JPEG", fSize=13, size={50,23},pos={120,555},proc=ButtonProcR2D_SaveImageAsJPEG
	Button button3 title="PDF", fSize=13, size={50,23},pos={180,555},proc=ButtonProcR2D_SaveImageAsPDF
	Button button4 title="TIFF", fSize=13, size={50,23},pos={240,555},proc=ButtonProcR2D_SaveImageAsTIFF
	Checkbox cb1 title="Use Sample Name", fSize=13, pos={50, 590}
	Checkbox cb2 title="Export All", fSize=13, pos={220, 590}
	
	// Misc
	GroupBox group0 pos={30,391},size={300,2}
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
			
			NVAR low = :Red2DPackage:U_ColorLow
			NVAR high = :Red2DPackage:U_ColorHigh
			
			high = R2D_GetImagePopulationThreshold(imagew, 0.99)	// get 99% of pixels from low intensity
			low = 0.01*high
				
//			MatrixOP/FREE/O hh = maxval(imagew)
//			MatrixOP/FREE/O ll = minval(imagew)
//			low = ll[0]
//			high = hh[0]
//			low = 0.01*high	// this makes the image looks better than using real low value, modofied to 0.01 2025-12-16
			
			R2D_ApplyColorTable()
//			R2D_ColorRangeAdjust_worker("", low, high)
		
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
				R2D_ApplyColorTable()
//				R2D_ColorRangeAdjust_worker("", low, high)
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
			
			NVAR LogColor = :Red2DPackage:U_LogColor
			LogColor = checked
//			ModifyImage ''#0 log=LogColor
			R2D_ApplyColorTable()	
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function R2D_ReverseColor_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			NVAR reverseColor = :Red2DPackage:U_reverseColor
			reverseColor = checked
//			ModifyImage ''#0 log=LogColor
			R2D_ApplyColorTable()	
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function R2D_CustomColor_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			
			ControlInfo/W=Display2D cb3		// use custom color?
			If(V_Value == 0)	// use built-in color
				SVAR BuiltinColorTable = :Red2DPackage:U_BuiltinColorTable
				SVAR ColorTable = :Red2DPackage:U_ColorTable
				ColorTable = BuiltinColorTable
				R2D_ApplyColorTable()	
			else	// use custom color
				SVAR CustomColorTable = :Red2DPackage:U_CustomColorTable
				SVAR ColorTable = :Red2DPackage:U_ColorTable
				ColorTable = "root:Packages:ColorTables:" + CustomColorTable	// custom color wave needs full path
				R2D_ApplyColorTable()							
			endif
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function R2D_SelectBuiltinColor_PopProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr

			String/G :Red2DPackage:U_BuiltinColorTable
			SVAR BuiltinColorTable = :Red2DPackage:U_BuiltinColorTable
			BuiltinColorTable = popStr
			
			ControlInfo/W=Display2D cb3		// use custom color?
			If(V_Value == 0)	// use built-in color
				String/G :Red2DPackage:U_ColorTable
				SVAR ColorTable = :Red2DPackage:U_ColorTable
				ColorTable = BuiltinColorTable
				R2D_ApplyColorTable()			
			endif
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function R2D_SelectCustomColor_PopProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			String/G :Red2DPackage:U_CustomColorTable
			SVAR CustomColorTable = :Red2DPackage:U_CustomColorTable
			CustomColorTable = popStr
			
			ControlInfo/W=Display2D cb3		// use custom color?
			If(V_Value == 1)	// use custom color
				String/G :Red2DPackage:U_ColorTable
				SVAR ColorTable = :Red2DPackage:U_ColorTable
				ColorTable = "root:Packages:ColorTables:" + CustomColorTable		// custom color wave needs full path
				R2D_ApplyColorTable()		
			endif
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function R2D_ApplyColorTable()

			SVAR ColorTable = :Red2DPackage:U_ColorTable	// get effective color table name
			NVAR LogColor = :Red2DPackage:U_LogColor
			NVAR reverseColor = :Red2DPackage:U_reverseColor
			NVAR low = :Red2DPackage:U_ColorLow
			NVAR high = :Red2DPackage:U_ColorHigh
			
			DoWindow IntensityImage
			If(V_flag != 0)
				R2D_ColorRangeAdjust_worker(ColorTable, low, high, LogColor, reverseColor)
			Endif

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

// Recursive function with Depth Limit and Output Mode
// Parameters:
//   dfr:      The starting data folder reference (e.g., root:)
//   mode:     0 = Full Path, 1 = Name Only
//   maxLevel: 0 = Current folder only
//             1 = Go 1 folder deep
//            -1 = Infinite recursion (All folders)
Function/S R2D_RecursiveGetLUTList(dfr, mode, maxLevel, [rootPath])
    DFREF dfr
    Variable mode
    Variable maxLevel
    String rootPath 
    
    String startPath
    if (ParamIsDefault(rootPath))
        startPath = GetDataFolder(1, dfr)
    else
        startPath = rootPath
    endif

    String list = ""
    String currentPath = GetDataFolder(1, dfr)
    Variable i
    String thisName
    String fullPath, relPath
    
    // --- PART 1: Process Waves in Current Folder ---
    Variable numWaves = CountObjectsDFR(dfr, 1) 
    
    For (i = 0; i < numWaves; i += 1)
        thisName = GetIndexedObjNameDFR(dfr, 1, i)
        
        // ★重要: ここで名前を安全な形に変換します
        String safeName = PossiblyQuoteName(thisName)
        
        // 参照を作るときは元の名前($thisName)を使います
        Wave w = dfr:$thisName
        
        if (WaveDims(w) == 2 && WaveType(w, 1) == 1)
            
            if (mode == 1)
                // mode 1: 安全な名前だけを出力
                list += safeName + ";"
            elseif (mode == 2)
                // mode 2: パス結合時も safeName を使う
                fullPath = currentPath + safeName
                relPath = ReplaceString(startPath, fullPath, "") 
                list += relPath + ";"
            else
                // mode 0: フルパス結合時も safeName を使う
                list += currentPath + safeName + ";"
            endif
            
        endif
    EndFor
    
    // --- PART 2: Check Depth Limit ---
    if (maxLevel == 0)
        return list
    endif
    
    Variable nextLevel
    if (maxLevel < 0)
        nextLevel = -1 
    else
        nextLevel = maxLevel - 1 
    endif
    
    // --- PART 3: Recurse into Subfolders ---
    Variable numFolders = CountObjectsDFR(dfr, 4) 
    String subFolderName
    
    For (i = 0; i < numFolders; i += 1)
        subFolderName = GetIndexedObjNameDFR(dfr, 4, i)
        DFREF subDF = dfr:$subFolderName
        
        // 再帰処理
        list += R2D_RecursiveGetLUTList(subDF, mode, nextLevel, rootPath=startPath)
    EndFor
    
    return list
End

//Function/S R2D_RecursiveGetLUTList(dfr, mode, maxLevel, [rootPath])
//    DFREF dfr
//    Variable mode
//    Variable maxLevel
//    String rootPath // 再帰処理用に「最初のパス」を記憶する変数
//    
//    // --- 0. 開始パスの特定 ---
//    // 最初の呼び出し（ユーザーからの呼び出し）では rootPath は省略されているため、
//    // 現在の dfr を「基準パス (startPath)」として設定します。
//    String startPath
//    if (ParamIsDefault(rootPath))
//        startPath = GetDataFolder(1, dfr)
//    else
//        startPath = rootPath
//    endif
//
//    String list = ""
//    String currentPath = GetDataFolder(1, dfr)
//    Variable i
//    String thisName
//    String fullPath, relPath
//    
//    // --- PART 1: Process Waves in Current Folder ---
//    Variable numWaves = CountObjectsDFR(dfr, 1) 
//    
//    For (i = 0; i < numWaves; i += 1)
//        thisName = GetIndexedObjNameDFR(dfr, 1, i)
//        
//        Wave w = dfr:$thisName
//        
//        if (WaveDims(w) == 2 && WaveType(w, 1) == 1)
//            
//            if (mode == 1)
//                // mode 1: ウェーブ名のみ
//                list += thisName + ";"
//            elseif (mode == 2)
//                // mode 2: 相対パス (基準パス以降のみ)
//                fullPath = currentPath + thisName
//                // フルパスから基準パス(startPath)を削除して相対化
//                relPath = ReplaceString(startPath, fullPath, "") 
//                list += relPath + ";"
//            else
//                // mode 0: フルパス
//                list += currentPath + thisName + ";"
//            endif
//            
//        endif
//    EndFor
//    
//    // --- PART 2: Check Depth Limit ---
//    if (maxLevel == 0)
//        return list
//    endif
//    
//    Variable nextLevel
//    if (maxLevel < 0)
//        nextLevel = -1 
//    else
//        nextLevel = maxLevel - 1 
//    endif
//    
//    // --- PART 3: Recurse into Subfolders ---
//    Variable numFolders = CountObjectsDFR(dfr, 4) 
//    String subFolderName
//    
//    For (i = 0; i < numFolders; i += 1)
//        subFolderName = GetIndexedObjNameDFR(dfr, 4, i)
//        DFREF subDF = dfr:$subFolderName
//        
//        // 再帰呼び出し: 
//        // ここで現在の startPath を第4引数として渡し、基準位置を維持します
//        list += R2D_RecursiveGetLUTList(subDF, mode, nextLevel, rootPath=startPath)
//    EndFor
//    
//    return list
//End

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
//	NVAR LogColor = :Red2DPackage:U_LogColor
//	SVAR ColorTable = :Red2DPackage:U_ColorTable

	If(row < NumInList) // Check if selected row in range. If out of range do nothing.
//		// Do nothing.
//	Else
	
//		If (Strlen(ColorTable) == 0) // Use Turbo when a is not selected.
//			ColorTable = "Turbo" 
//		endif
		String SelImageName = ImageList[row] // Get selected Imagename by using the flag row.
		
		DoWindow IntensityImage // Check if there is a window named 2DImageWindow. Exist returns 1 else 0.	
		If(V_flag == 0) // Create a new image window with name as 2DImageWindow if not exists.
			NewImage/K=1/N=IntensityImage $SelImageName
			R2D_ApplyColorTable()	
////			ModifyImage/W=IntensityImage $(SelImageName)	 ctab= {1,*,ColdWarm,0},log=1
//			if(numtype(low) == 2 || numtype(high) == 2 || numtype(LogColor) == 2)
//				ModifyImage/W=IntensityImage $(SelImageName)	 ctab= {1,*,$ColorTable,0},log=1
//				low = 1
//				high = wavemax($SelImageName)
//				LogColor = 1
//			elseif(low == 0 && high == 0)
//				ModifyImage/W=IntensityImage $(SelImageName)	 ctab= {1,*,$ColorTable,0},log=1
//				low = 1
//				high = wavemax($SelImageName)
//				LogColor = 1
//			else
//				ModifyImage/W=IntensityImage $(SelImageName)	 ctab= {low,high,$ColorTable,0},log=LogColor
//			endif
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

Function R2D_ColorRangeAdjust_worker(LUT, low, high, LogColor, reverseColor, [tarWinName])
	String LUT
	variable low
	variable high
	variable LogColor
	variable reverseColor
	string tarWinName
	
	If(stringmatch(LUT, "*:*"))	// custom made look up table
		If(!WaveExists($LUT))		// if the custom color wave does not exist
			printf "Selected Color Wave does not exists: %s\r", LUT
			return -1
		Endif
	Endif
	
	If(ParamIsDefault(tarWinName))
		ModifyImage ''#0 ctab= {low,high,$LUT,reverseColor}, log=LogColor
	Else
		If(Strlen(WinList(tarWinName, ";","WIN:1"))>0)
			ModifyImage/W=tarWinName ''#0 ctab= {low,high,$LUT,reverseColor}, log=LogColor
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


Function R2D_GetImagePopulationThreshold(wImage, thresh)
    Wave wImage
    Variable thresh

    // 1. Get stats to determine histogram range
    ImageStats/M=1 wImage
    Variable maxVal = V_max
    
    // Safety check: Return NaN if max is invalid or <= 0
    if (numtype(maxVal) != 0 || maxVal <= 0)
        return NaN
    endif
    
    // 2. Set up Histogram Parameters (5000 bins)
    Variable nBins = 500000
    Variable binWidth = maxVal / nBins
    
    Make/FREE/O/N=(nBins) wHist
    
    // 3. Compute Histogram (Range: 0 to Max)
    // NaNs are automatically ignored. Zeros fall into Bin 0.
    Histogram/B={0, binWidth, nBins} wImage, wHist
    
    // 4. Remove Zeros from Histogram Wave
    wHist[0] = 0 // Explicitly zero out the bin containing the 0s
    
    // 5. Calculate Valid Population
    Variable totalPopulation = sum(wHist)
    Variable targetIndex = totalPopulation * thresh
    
    Variable currentCount = 0
    Variable i
    Variable thresholdVal = NaN
    
    // 6. Find threshold by accumulating counts
    for(i = 1; i < nBins; i += 1)
        currentCount += wHist[i]
        if(currentCount >= targetIndex)
            thresholdVal = i * binWidth 
            break
        endif
    endfor
    
//    Print "95% Threshold (Fast Hist):", thresholdVal
    return thresholdVal
    
End