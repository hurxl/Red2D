#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

/////////SHOW&HIDE TRACES//////////
Function R2D_ShowHideTraces()
//	Variable refresh
	
	// Check if the panel exist
   DoWindow ShowHideTraces
	If(V_flag == 0)  // if panel does not exist, create new one
		NewPanel/K=1/N=ShowHideTraces/W=(100,100,800,900)
		SetWindow ShowHideTraces, hook(ShowHideHook) = ShowHideWindowHook
	Else
		DoWindow/F ShowHideTraces  // if exists, bring it front
	Endif
	
	// Create a datafolder to store info
	If(!DataFolderExists("root:Packages"))
		NewDataFolder root:Packages
	Endif
	If(!DataFolderExists("root:Packages:ShowHide_Package"))
		NewDataFolder root:Packages:ShowHide_Package
	Endif
	
	// Create Match strings to filter SampleName and ImageName.	
	String/G root:Packages:ShowHide_Package:TraceMatchStr  // for samplename
	String/G root:Packages:ShowHide_Package:TraceMatchStr2  // for imagename
	SVAR TraceMatchStr = root:Packages:ShowHide_Package:TraceMatchStr
	SVAR TraceMatchStr2 = root:Packages:ShowHide_Package:TraceMatchStr2
	If(strlen(TraceMatchStr) < 1)  // initialize string to prevent bug
		TraceMatchStr = "*"
	Endif
	If(strlen(TraceMatchStr2) < 1)  // initialize string to prevent bug
		TraceMatchStr2 = "*"
	Endif
	
	R2D_CreateTraceList(TraceMatchStr, TraceMatchStr2)  // Create a Tracelist of Topimage
	String TopGraphName = winName(0,1)  // Get Window Name of Top Image window
	Make/O/W/U root:Packages:ShowHide_Package:myColors = {{0,0,0},{62000,62000,62000}}  // colored background for listbox
	wave myColors = root:Packages:ShowHide_Package:myColors
	MatrixTranspose myColors  //it seems I have to transpose the mycolors, otherwise it does not work.
	
	// Create FontSize variable
	Variable/G root:Packages:ShowHide_Package:U_relFontSize
	
	// Create listbox named ImageList and make it follows ListBoxProc
	ListBox List0 win = ShowHideTraces, listWave=root:Packages:ShowHide_Package:Z_TracesList, selWave=root:Packages:ShowHide_Package:Z_StateOfTracesList, colorWave=myColors
	ListBox List0 win = ShowHideTraces, userdata=TopGraphName+";"+"ShowHideTraces", proc=ListControl_SelectTraces
	ListBox List0 win = ShowHideTraces, mode=1, size={695,550}, pos={5,95}, fSize=13, widths={30,180,180,400}, userColumnResize=1
	
	Button button0 win = ShowHideTraces, title="Refresh",size={120,23},pos={100,10},proc=BP_RefreshTraceList
	Button button1 win = ShowHideTraces, title="Annotate with ImageName",size={200,23},pos={50,660},proc=BP_NormalAnnotation, help={"Create annotation on top graph."}
	Button button2 win = ShowHideTraces, title="Annotate with SampleName",size={200,23},pos={50,730},proc=BP_SampleNameAnnotation, help={"Create annotation on top graph based on SampleName."}
	Button button3 win = ShowHideTraces, title="Reorder by ImageName",size={200,23},pos={50,690},proc=BP_R2DReorderTracesByImageName
	Button button4 win = ShowHideTraces, title="Reorder by SampleName",size={200,23},pos={50,760},proc=BP_R2DReorderTracesBySampleName
	Button button5 win = ShowHideTraces, title="Show Everthing",size={150,23},pos={340,20},proc=BP_ShowEverything
	Button button6 win = ShowHideTraces, title="Hide Everthing",size={150,23},pos={340,50},proc=BP_HideEverything
	Button button7 win = ShowHideTraces, title="Show All in List",size={150,23},pos={510,20},proc=BP_ShowAllInList
	Button button8 win = ShowHideTraces, title="Hide All in List",size={150,23},pos={510,50},proc=BP_HideAllInList
	Button button9 win = ShowHideTraces, title="Remove Hidden Annotations",size={200,23},pos={400,750},proc=RemoveHidenAnnotations
	SetVariable setvar0 win = ShowHideTraces, title="SampleName filter", size={280,23},pos={15,60}, fSize=13
	SetVariable setvar0 win = ShowHideTraces, value=TraceMatchStr, help={"Type * to match everything. * is Sa wildcard."}
	SetVariable setvar1 win = ShowHideTraces, title="ImageName filter", size={280,23},pos={15,40}, fSize=13
	SetVariable setvar1 win = ShowHideTraces, value=TraceMatchStr2, help={"Type * to match everything. * is a wildcard."}
	Slider slider0 size={300,20}, pos={330, 670}, vert=0,limits={10,500,10},proc=ShowHideLegendFontSizeSliderProc
	
End

Function R2D_CreateTraceList(matchStr, matchStr2)
	string matchStr
	string matchStr2
	
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder root:Packages:ShowHide_Package

	// Get traces list and the number of traces.
	String TopGraphName = winName(0,1) // Get the name of top graph.
	String FullTraceLst = TraceNamelist(TopGraphName, ";", 1) // Get traces names from top graph with. bit 1=2^0 means all traces.
	Variable NumOfFullTraces = itemsinlist(FullTraceLst) // Get number of items in List
	Wave/T FullTraceLst_twave = ListToTextWave(FullTraceLst,";") // Create a text wave reference containing ImaNLst
	
	// Check if there is a trace on top window, if not end procedure.
	If(NumOfFullTraces == 0)
		DoAlert 0, "No traces on top Graph."
		Return 0
		SetDataFolder saveDFR
	Endif
	
	// Collect trace names on top graph
	Make/O/T/N=(NumOfFullTraces,4) Z_FullTracesList = ""
	SetDimLabel 1, 0, cb, Z_FullTracesList	// check box will not be filled but I need it to match the dimension of TracesList and StateList.
	SetDimLabel 1, 1, ImageName, Z_FullTracesList
	SetDimLabel 1, 2, SampleName, Z_FullTracesList
	SetDimLabel 1, 3, Datafolder, Z_FullTracesList
	Z_FullTracesList[][1] = FullTraceLst_twave[x]
	
	// Collect the corresponding SampleName that may show the sample names. If exist.
	// Get trace name -> get full path of the wave -> get corresponding samplename(datasheet)
	variable j
	string tracesDF, trace_path, Datasheet_path, wavnam
	For(j=0; j<NumOfFullTraces; j++)
		wave targetwave = TraceNameToWaveRef("", Z_FullTracesList[j][1])
		wavnam = NameOfWave(targetwave)
		tracesDF = GetWavesDataFolder(targetwave, 1)	// 1: folder path without wave name
//		trace_path = GetWavesDataFolder(targetwave, 2)	// 2: full path
		Datasheet_path = tracesDF+":Red2DPackage:Datasheet"
		
		Z_FullTracesList[j][3] = RemoveListItem(0, tracesDF, ":")
		wave/T datasheet = $Datasheet_path
		
		If(WaveExists(datasheet)==1)
			Make/FREE/T/O/N=(DimSize(Datasheet,0)) ImageName = Datasheet[p][%ImageName]
			FindValue/TEXT=(RemoveEnding(wavnam, "_i")) ImageName		
			If(V_value != -1) // V_value stores the index from FindValue
				Make/FREE/T/O/N=(DimSize(Datasheet,0)) SampleName = Datasheet[p][%SampleName]
				Z_FullTracesList[j][2] = SampleName[V_value]
			Endif
		Endif
		
	Endfor
	
	// Get hide status of each trace
	// I cannot store the state information in the Z_FullTraceList because it is a textwave. Z_FullStateOfTracesList is a numeric wave.
	// Z_FullTraceList is a 2D wave, whereas the Z_FullStateOfTracesList is a 3D wave. The 1st layer in StateList stores the checkbox state
	// the 2nd layer stores the row color.
	Make/O/N=(NumOfFullTraces,4, 2) Z_FullStateOfTracesList = 0  //The dimensionality of the selwave (state wave ) must be the same with listwave (tracewave).
	Z_FullStateOfTracesList[][0][0] = 2^5+2^4 //"bit" to control and check checkbox in listbox. bit5 means checkbox effective, 4 means checked.
	variable i
	variable SHs //show hide sign
	For(i=0; i < NumOfFullTraces; i+=1)
		SHs = Str2num(StringByKey("hideTrace(x)", TraceInfo("","",i),"=")) //Get status of traces show and hide using TraceInfo.
		Z_FullStateOfTracesList[i][0][0] -= SHs*2^4 //SHs is 0 when shown, and 1 when hide.
	Endfor
	
	/// filter the list with matchStr
	Duplicate/O/T Z_FullTracesList, Z_TracesList   // Z_tracesList has the same number of traces as the full list at this time.
	Duplicate/O Z_FullStateOfTracesList, Z_StateOfTracesList  // Z_tracesList has the same number of entries as the full list at this time.
	String tempName, tempName2
	For(j=NumOfFullTraces-1; j>=0; j--)  // When using DeltePoints, I need to use the reverse for loop.
		/// If the sample name in Z_tracelist does not match the matchStr, delete the rows
		/// filter with SampleName
		tempName = RemoveEnding(Z_TracesList[j][2], ";")  // Z_traclist[][2] stores the SampleName
		If(!stringmatch(tempName, matchStr))
			Z_TracesList[j][2] = "ToBeDeleted"
		Endif
		/// filter with ImageName
		tempName2 = RemoveEnding(Z_TracesList[j][1], ";")  // Z_traclist[][2] stores the SampleName
		If(!stringmatch(tempName2, matchStr2))
			Z_TracesList[j][1] = "ToBeDeleted"
		Endif		
	Endfor
	
	For(j=NumOfFullTraces-1; j>=0; j--)
		If(cmpstr(Z_TracesList[j][1], "ToBeDeleted")==0 || cmpstr(Z_TracesList[j][2], "ToBeDeleted")==0 )
			DeletePoints/M=0 j, 1, Z_TracesList
			DeletePoints/M=0 j, 1, Z_StateOfTracesList
		Endif
	Endfor
	
	If(DimSize(Z_StateOfTracesList,0) > 0)
		Z_StateOfTracesList[][][1] = mod(p,2)==0 ? 0:1  // create alternating colors in the listbox
		SetDimLabel 2,1,backColors,Z_StateOfTracesList  // setdimlabel to backColors is a key to enable the colorWave works in the listbox.
	Endif

	
	SetDataFolder saveDFR

End

Function SampleNameToAnnotation()

	Wave/T Z_FullTraceList = root:Packages:ShowHide_Package:Z_FullTracesList
	Variable numOfItems = Dimsize(Z_FullTraceList,0)

	String annotationtext =""
	
	Variable j
	For(j = 0; j < numOfItems; j++)

		annotationtext += "\\s(" + Z_FullTraceList[j][1] + ") " + Z_FullTraceList[j][2]
		If(j < numOfItems - 1)
			annotationtext += "\r"
		Endif
	
	Endfor
	
	Legend/C/N=text0/J Annotationtext

End

Function SetAnnotationFontSize(LegendName, relFontSize)
	string LegendName
	variable relFontSize
	
	string annolist = AnnotationList("")
	if(strlen(ListMatch(annolist, "text0")) == 0)
		Print "No legend exists."
		return -1
	endif
	
	// make the new font size code
	string newRelFontSizeCode
	if(relFontSize<=0)
		newRelFontSizeCode = "\\Zr100"
	elseif(relFontSize<10)
		newRelFontSizeCode = "\\Zr00"+num2str(relFontSize)
	elseif(relFontSize<100)
		newRelFontSizeCode = "\\Zr0"+num2str(relFontSize)
	elseif(relFontSize<1000)
		newRelFontSizeCode = "\\Zr"+num2str(relFontSize)
	else
		newRelFontSizeCode = "\\Zr100" // if unexpected size is provided
	endif
	newRelFontSizeCode += "\r"

	// get current legend text
	string allinfo = AnnotationInfo("", LegendName)
	string legendText = StringByKey("TEXT", allinfo) // text part is stored as the value of the key TEXT.
	legendText = ReplaceString("\\\\", legendText, "\\") // the text stores \ as \\
	legendText = ReplaceString("\\r", legendText, "\r") // the text stores \r as \\r
	

	// search the code for font size
	string ZrTextList
	variable numZrItems
	string ZrText
	variable NumericPart
	string FontSizeCode
	ZrTextList = ListMatch(legendText, "Zr*", "\\") // get a list of items starting with Zr
	numZrItems = itemsInList(ZrTextList) // get the number of items
	if(numZrItems == 0) // No item starts with Zr
		ZrText = ""
	else
		// check if the found Zr item is the font code
		variable i
		Do
			ZrText = StringFromList(i, ZrTextList, "\\") // get a Zr item
			NumericPart = str2Num(ZrText[2,4]) // get the numeric part of Zr item
			if(strlen(ZrText) == 6 && numtype(NumericPart) == 0) // if the code is Font Size Code
				break // found the code. stop loop.
			else
				ZrText = "" // Latter codes need true ZrText.
			endif
			i++
		While(i < numZrItems)
	endif

	string newLegendText
	if(strlen(ZrText) == 0) // if the font size code does not exist in current annotation
		newLegendText = newRelFontSizeCode + legendText
	else // if the font size code exists
		FontSizeCode = "\\" + ZrText
		newLegendText = ReplaceString(FontSizeCode, legendText, newRelFontSizeCode)
	endif

	Legend/C/N=text0/J/F=0 newLegendText

End


Function R2D_ReorderTraces(order)
	variable order  // 0 for imagename, 1 for samplename

	Wave/T Z_FullTracesList = root:Packages:ShowHide_Package:Z_FullTracesList  // use full trace list because reorder affects all traces
	Variable numOfFullItems = Dimsize(Z_FullTracesList,0)
	
	Make/T/O/FREE/N=(numOfFullItems) ImageName, SampleName
	ImageName[] = Z_FullTracesList[p][1]
	SampleName[] = Z_FullTracesList[p][2]
	
	/// Get Samplenamelsit in alphabet order
	if(order == 0)
		Sort/A ImageName, ImageName, SampleName  // sort by ImageName in alphabet order
	elseif(order == 1)
		Sort/A SampleName, SampleName, ImageName  // sort by SampleName in alphabet order
	endif
	
	variable i, j
	j = 0
	string trace
	for(i=0; i<numOfFullItems; i++)
			trace = ImageName[i]
			ReorderTraces _front_, {$trace}
	endfor
	
	R2D_ShowHideTraces()  // refresh the Z_tracesList and the panel
	
	
	if(order == 0)
		Legend/C/N=text0 ""  // sort by ImageName in alphabet order
	elseif(order == 1)
		SampleNameToAnnotation()  // refresh the annotation  // sort by SampleName in alphabet order
	endif
	NVAR relFontSize = root:Packages:ShowHide_Package:U_relFontSize
	SetAnnotationFontSize("text0", relFontSize)

End


Function RemoveHidenAnnotations(LegendName)
	string LegendName	// it is text0 by default

	// This must be a very useful function. 2023-06-10
	// Originally, I thought to use Z_fullTracesList and Z_fullStateList to re-legend the graph.
	// But I realized that I need to know to how the current legen is made for. for image name or sample name.
	// A better idea is to get the hidden traces using TraceInfo and check the text0, then remove the matched traces.
	
	// Get annotation text as a list
	string allinfo = AnnotationInfo("", LegendName)
	string legendText = StringByKey("TEXT", allinfo) // text part is stored as the value of the key TEXT.
	legendText = ReplaceString("\\\\", legendText, "\\") // the text stores \ as \\
	legendText = ReplaceString("\\r", legendText, "\r") // the text stores \r as \\r
	
	// Get ongraph traces list
	string FullTraceList = TraceNamelist("",";",1)	// bit 1 for all traces
	string OnGraphTraceList = TraceNamelist("",";",1+4)	// bit 1 + bit 2 for traces on graph
	string HiddenTraceList = RemoveFromList(OnGraphTraceList, FullTraceList)
	
	// Remove list items that do not exist on ongraph traces list
	variable numOfFullTraces = itemsInList(FullTraceList)
	variable numOfHiddenTraces = itemsInList(HiddenTraceList)
	string newLegendText = legendText
	
	variable i
	string matchStr
	string targetText
	for(i=0; i<numOfHiddenTraces; i++)
		matchStr = "*\\s(" + StringFromList(i, HiddenTraceList) + ")*"	// Compose the base legend text of the hidden traces
		targetText = ListMatch(newLegendText, matchStr, "\r")	// Find the index or full item text of hidden trace in legendText
		newLegendText = RemoveFromList(targetText, newLegendText, "\r")// Remove the item
	endfor
	
	// Set the annotation text again
	Legend/C/N=text0/J newLegendText

End

Function ListControl_SelectTraces(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	String userdata = lba.userdata // Not in use because I did not find a right way to focus the window.
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
			If(row < DimSize(selWave,0))  // prevent out of index error when user selects a row out of the list
			Switch(selWave[row][0])				
				Case 32:
					ModifyGraph/W=$graphname hideTrace($(listWave[row][1]))=0
					selWave[row][0] += 2^4 //Add bit 4 to mark checkbox
					break
				Case 48:
					ModifyGraph/W=$graphname hideTrace($(listWave[row][1]))=1
					selWave[row][0] -= 2^4 //Remove bit 4 to unmark checkbox
					break
			Endswitch
			Endif
			
			break
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			Switch(selWave[row][0])
				Case 32:
					ModifyGraph/W=$graphname hideTrace($(listWave[row][1]))=1
					break
				Case 48:
					ModifyGraph/W=$graphname hideTrace($(listWave[row][1]))=0
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
			R2D_ShowHideTraces()

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



Function BP_SampleNameAnnotation(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NVAR relFontSize = root:Packages:ShowHide_Package:U_relFontSize
			SampleNameToAnnotation()
			SetAnnotationFontSize("text0", relFontSize)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function BP_RemoveHidenAnnotations(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NVAR relFontSize = root:Packages:ShowHide_Package:U_relFontSize
			RemoveHidenAnnotations("text0")
			SetAnnotationFontSize("text0", relFontSize)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function BP_NormalAnnotation(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NVAR relFontSize = root:Packages:ShowHide_Package:U_relFontSize
			Legend/C/N=text0 ""
			SetAnnotationFontSize("text0", relFontSize)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function BP_R2DReorderTracesByImageName(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			R2D_ReorderTraces(0)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function BP_R2DReorderTracesBySampleName(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			R2D_ReorderTraces(1)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function BP_ShowEverything(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			ModifyGraph hideTrace=0
			
			R2D_ShowHideTraces()

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function BP_HideEverything(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			ModifyGraph hideTrace=1
			
			R2D_ShowHideTraces()

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function BP_ShowAllInList(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			Wave/T Traceslist = root:Packages:ShowHide_Package:Z_TracesList
			Variable numInList = DimSize(Traceslist,0)
			Variable i
			String TraceName_showhide
			For(i=0; i<numInList; i++)
				TraceName_showhide = Traceslist[i][1]
				ModifyGraph hideTrace($TraceName_showhide)=0; DelayUpdate
			Endfor
			
			R2D_ShowHideTraces()

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



Function BP_HideAllInList(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			Wave/T Traceslist = root:Packages:ShowHide_Package:Z_TracesList
			Variable numInList = DimSize(Traceslist,0)
			Variable i
			String TraceName_showhide
			For(i=0; i<numInList; i++)
				TraceName_showhide = Traceslist[i][1]
				ModifyGraph hideTrace($TraceName_showhide)=1; DelayUpdate
			Endfor
			
			R2D_ShowHideTraces()

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ShowHideWindowHook(s)
	STRUCT WMWinHookStruct &s
	
	Variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.

	switch(s.eventCode)
		case 0:	// window activated
			R2D_ShowHideTraces()
			hookResult = 1
			break		
	endswitch

	return hookResult	// If non-zero, we handled event and Igor will ignore it.
End

Function ShowHideLegendFontSizeSliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -3: // Control received keyboard focus
		case -2: // Control lost keyboard focus
		case -1: // Control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				NVAR relFontSize = root:Packages:ShowHide_Package:U_relFontSize
				relFontSize = sa.curval
				SetAnnotationFontSize("text0", relFontSize)
			endif
			break
	endswitch

	return 0
End