#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/////////GUI//////////
Function Red2D_Display2D(refresh)
	variable refresh

	String reflist = wavelist("*",";","DIMS:2") //Get wavelist from current folder limited for 2D waves
	Wave/T reftw = ListToTextWave(reflist,";") // Create a text wave reference containing reflist
	Variable NumInList = itemsinlist(reflist) // Get number of items in List

	If(DatafolderExists("Red2DPackage")==0)
		NewDataFolder :Red2DPackage
	Endif

	Duplicate/T/O reftw, :Red2DPackage:ImageList

	//Create a new panel named DisplayImage for listbox
	If(refresh == 0)
		NewPanel/K=1/N=Display2D/W=(1200,100,1550,550)
	Endif
	
	//Create listbox named ImageList and make it follows ListBoxProc
	ListBox lb listWave=:Red2DPackage:ImageList, mode=1, size={350,300}, fSize=13, proc=ListBoxProcShow2D
	Button button0 title="Show/Hide Sector Mask",size={150,25},pos={100,320},proc=ButtonProcShowHideSM
	Button button1 title="Show/Hide ROI Mask",size={150,25},pos={100,360},proc=ButtonProcShowHideRM
	Button button2 title="Refresh",size={150,25},pos={100,400},proc=ButtonProcRefreshList
	
End

Function ButtonProcShowHideSM(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			ShowHideSectorMask()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcShowHideRM(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			ShowHideROIMask()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcRefreshList(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			Red2D_Display2D(1)
			
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
			Show2D(row)
			break
	endswitch

	return 0
End

//////////Main Code////////////

Static Function Show2D(row)
	variable row
	
	wave/T ImageList = :Red2DPackage:ImageList // create a wave referece to a text wave "Z_ImageList"
	Variable NumInList = DimSize(ImageList,0) // Get items number in Imagelist

	If(row>NumInList-1) // Check if selected row in range. If out of range do nothing.
		// Do nothing.
	Else
		String SelImageName = ImageList[row] // Get selected Imagename by using the flag row.
		
		DoWindow IntensityImage // Check if there is a window named 2DImageWindow. Exist returns 1 else 0.	
		If(V_flag == 0) // Create a new image window with name as 2DImageWindow if not exists.
			NewImage/N=IntensityImage $(SelImageName)	
			ModifyImage $(SelImageName)	 ctab= {1,*,ColdWarm,0},log=1
		Else // Replace selected images on the window named 2DImageWindow.
			Dowindow/F IntensityImage // Activate window ImageGraph
			String OldImage = ImageNameList("IntensityImage",";") // Get existing ImageName in the window ImageGraph
			ReplaceWave image = $(StringFromList(0,OldImage)), $(SelImageName) //Replace images. image is a flag here	
		Endif
				
		//Set cursor properties.
		Cursor /M/C=(65535,65535,65535)/S=1 A
		Cursor /M/C=(65535,65535,65535)/S=1 B
		Cursor /M/C=(65535,65535,65535)/S=1 C
		Cursor /M/C=(65535,65535,65535)/S=1 D
		Cursor /M/C=(65535,65535,65535)/S=1 E
		Cursor /M/C=(65535,65535,65535)/S=1 F
		Cursor /M/C=(65535,65535,65535)/S=1 G
		Cursor /M/C=(65535,65535,65535)/S=1 H
		Cursor /M/C=(65535,65535,65535)/S=1 I
		Cursor /M/C=(65535,65535,65535)/S=2 J
				
	Endif
End

Static Function ShowHideSectorMask()
	
	/// check if in the 2D folder
	If(Red2Dimagelistexist() == -1)
		return -1
	Endif
	
	/// main
	wave SectorMask = :Red2DPackage:SectorMask
	
	If(WaveExists(SectorMask) != 0)
		string refstring = ListMatch(ImageNameList("IntensityImage",";"), "SectorMask")
		variable OnGraph = strlen(refstring)
		
		If(OnGraph == 0)
			AppendImage/T/W=IntensityImage SectorMask
			ModifyImage/Z SectorMask explicit=1, eval={1,0,0,0,0}, eval={0,60000,60000,60000,50000}
		Else
			RemoveImage/Z/W=IntensityImage SectorMask
		Endif
	
	Else
		RemoveImage/Z/W=IntensityImage SectorMask
		Print "No mask exist."
	Endif
	
End

Static Function ShowHideROIMask()
	
	/// check if in the 2D folder
	If(Red2Dimagelistexist() == -1)
		return -1
	Endif
	
	/// main
	wave ROIMask = :Red2DPackage:ROIMask
	
	If(WaveExists(ROIMask) != 0)
		string refstring = ListMatch(ImageNameList("IntensityImage",";"), "ROIMask")
		variable OnGraph = strlen(refstring)
	
		If(OnGraph == 0)
			AppendImage/T/W=IntensityImage ROIMask
			ModifyImage/Z ROIMask explicit=1, eval={1,0,0,0,0}, eval={0,60000,60000,60000,50000}
		Else
			RemoveImage/Z/W=IntensityImage ROIMask
		Endif
		
	Else
		RemoveImage/Z/W=IntensityImage ROIMask
		Print "No mask exist."
	Endif
	
End