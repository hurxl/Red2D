#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function ShowHideTraces()

	// Convert namelist to a text wave, using for pannel references.
	DFREF saveDFR = GetDataFolderDFR()
	If(DataFolderExists("root:ShowHide_Package")==0)
		NewDataFolder root:ShowHide_Package
	Endif
	SetDataFolder root:ShowHide_Package

	// Get traces list and the number of traces.
	String TopGraphName = winName(0,1) // Get the name of top graph.
	String reflist = TraceNamelist(TopGraphName, ";", 1) // Get traces names from top graph with. bit 1=2^0 means all traces.
	Variable NumInList = itemsinlist(reflist) // Get number of items in List
	
	// Check if there is a trace on top window, if not end procedure.
	If(NumInList == 0)
		Print "No traces on top Graph."
		Return 0
	Endif
	
	Make/O/T/N=(NumInList) Z_TracesList
	Wave/T reftw = ListToTextWave(reflist,";") // Create a text wave reference containing reflist
	Z_TracesList = reftw[x]
	
	// Get show and hide status of each trace
	Make/O/N=(NumInList) Z_StateOfTracesList = 2^5+2^4 //"bit" to control and check checkbox in listbox. bit5 means checkbox effective, 4 means checked.
	variable i
	variable SHs //showhidesign
	For(i=0; i < NumInList; i+=1)
		SHs = Str2num(StringByKey("hideTrace(x)", TraceInfo("","",i),"=")) //Get status of traces show and hide using TraceInfo.
		Z_StateOfTracesList[i] -= SHs*2^4 //SHs is 0 when shown, and 1 when hide.
	Endfor
	
	SetDataFolder saveDFR
	
	//Create a new panel named DisplayImage for listbox
	String NewPanelName = TopGraphName + "_list"
	//Print NewPanelName
	NewPanel/N=$(NewPanelName)/W=(100,100,450,700)
	
	//Create listbox named ImageList and make it follows ListBoxProc
	ListBox TopTracesList listWave=root:ShowHide_Package:Z_TracesList, mode=1, selWave=root:ShowHide_Package:Z_StateOfTracesList
	ListBox TopTracesList proc=ListControl_SelectTraces, size={330,550}, pos={5,35}, fSize=13, userdata=TopGraphName+";"+NewPanelName
	Button button0 title="Refresh",size={120,25},pos={110,5},proc=BP_RefreshTraceList
	
End

Function ListControl_SelectTraces(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	String userdata = lba.userdata // Not in use because I did not find a right way to focus the window.
		
	Wave/T Z_TracesList = root:ShowHide_Package:Z_TracesList
	String panelname = StringFromList(1, userdata)
	String graphname = StringFromList(0, userdata)
	
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
			break
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			
			Switch(selWave[row])
				Case 32:
					ModifyGraph/W=$graphname hideTrace($(Z_TracesList[row]))=1
					break
				Case 48:
					ModifyGraph/W=$graphname hideTrace($(Z_TracesList[row]))=0
					break
			Endswitch
			
			break
	endswitch

	return 0
End

Function BP_RefreshTraceList(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
		// Convert namelist to a text wave, using for pannel references.
		DFREF saveDFR = GetDataFolderDFR()
		If(DataFolderExists("root:ShowHide_Package")==0)
			NewDataFolder root:ShowHide_Package
		Endif
		SetDataFolder root:ShowHide_Package

		// Get traces list and the number of traces.
		String TopGraphName = winName(0,1) // Get the name of top graph.

		String reflist = TraceNamelist(TopGraphName, ";", 1) // Get traces names from top graph with. bit 1=2^0 means all traces.
		Variable NumInList = itemsinlist(reflist) // Get number of items in List
	
		// Check if there is a trace on top window, if not end procedure.
		If(NumInList == 0)
			Print "No traces on top Graph."
			Return 0
		Endif
	
		Make/O/T/N=(NumInList) Z_TracesList
		Wave/T reftw = ListToTextWave(reflist,";") // Create a text wave reference containing reflist
		Z_TracesList = reftw[x]
	
		// Get show and hide status of each trace
		Make/O/N=(NumInList) Z_StateOfTracesList = 2^5+2^4 //"bit" to control and check checkbox in listbox. bit5 means checkbox effective, 4 means checked.
		variable i
		variable SHs //showhidesign
		For(i=0; i < NumInList; i+=1)
			SHs = Str2num(StringByKey("hideTrace(x)", TraceInfo("","",i),"=")) //Get status of traces show and hide using TraceInfo.
			Z_StateOfTracesList[i] -= SHs*2^4 //SHs is 0 when shown, and 1 when hide.
		Endfor
	
		SetDataFolder saveDFR
		
		//Create a new panel named DisplayImage for listbox
		String NewPanelName = TopGraphName + "_list"
		//Print NewPanelName
		RenameWindow $(winname(0,64)), $(NewPanelName)
		
		//Create listbox named ImageList and make it follows ListBoxProc
		ListBox TopTracesList listWave=root:ShowHide_Package:Z_TracesList, mode=1, selWave=root:ShowHide_Package:Z_StateOfTracesList
		ListBox TopTracesList proc=ListControl_SelectTraces, size={330,550}, pos={5,35}, fSize=13, userdata=TopGraphName+";"+NewPanelName
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End