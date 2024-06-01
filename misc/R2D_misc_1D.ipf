#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// *************************
// Combine multiple 1D profiles with different SDDs.
// *************************
Function R2D_SDDCombineranel() // Create a panel to combine waves of different SDD
	
	KillWindow/Z SDD_Combiner
	NewPanel/K=1/N=SDD_Combiner/W=(200,200,790,500)
	
	If(DatafolderExists("root:Red2Dpackage")==0)
		NewDataFolder root:Red2Dpackage
	Endif
	If(DatafolderExists("root:SDD_combined")==0)
		NewDataFolder root:SDD_combined
	Endif
	
	String/G root:Red2Dpackage:U_LongSDDIntPath
	String/G root:Red2Dpackage:U_midSDDIntPath
	String/G root:Red2Dpackage:U_ShortSDDIntPath
	String/G root:Red2Dpackage:U_OutputName = "temporary"
	Variable/G root:Red2Dpackage:U_prefactor_l
	Variable/G root:Red2Dpackage:U_prefactor_m
	Variable/G root:Red2Dpackage:U_prefactor_s
	NVAR U_prefactor_l = root:Red2Dpackage:U_prefactor_l
	NVAR U_prefactor_m = root:Red2Dpackage:U_prefactor_m
	NVAR U_prefactor_s = root:Red2Dpackage:U_prefactor_s
	If(numtype(U_prefactor_l) != 0 || U_prefactor_l == 0)
		U_prefactor_l = 1
	Endif
	If(numtype(U_prefactor_m) != 0 || U_prefactor_m == 0)
		U_prefactor_m = 1
	Endif
	If(numtype(U_prefactor_s) != 0 || U_prefactor_s == 0)
		U_prefactor_s = 1
	Endif
	Variable/G root:Red2Dpackage:U_Cursorlong
	Variable/G root:Red2Dpackage:U_Cursormid
	NVAR U_Cursorlong = root:Red2Dpackage:U_Cursorlong
	NVAR U_Cursormid = root:Red2Dpackage:U_Cursormid
	If(numtype(U_Cursorlong) != 0)
		U_Cursorlong = 1
	Endif
	If(numtype(U_Cursormid) != 0)
		U_Cursormid = 1
	Endif
	Variable/G root:Red2Dpackage:U_qindex_0
	Variable/G root:Red2Dpackage:U_qindex_1
	Variable/G root:Red2Dpackage:U_qindex_2
	Variable/G root:Red2Dpackage:U_qindex_3


	TitleBox title0 title="Full path of intensity wave of",pos={230,10},frame=0,fSize=13
	SetVariable setvar0 title="Long SDD ", pos={20,30},size={550,25}, fSize=13, value=root:Red2Dpackage:U_LongSDDIntPath, help={"You can copy a full path of trace from a graph."}
	SetVariable setvar1 title="Mid SDD   ", pos={20,55},size={550,25}, fSize=13, value=root:Red2Dpackage:U_midSDDIntPath, help={"You can copy a full path of trace from a graph."}
	SetVariable setvar2 title="Short SDD", pos={20,80},size={550,25}, fSize=13, value=root:Red2Dpackage:U_ShortSDDIntPath, help={"You can copy a full path of trace from a graph."}
	TitleBox title1 title="Y-Multiplier",pos={160,130},frame=0,fSize=13
	TitleBox title2 title="Cursor positions on",pos={310,130},frame=0,fSize=13
	SetVariable setvar3 title="L ", pos={160,150},size={100,25}, fSize=13, value=U_prefactor_l, limits={0,inf,0.01}, proc=VarProcYMultiply
	SetVariable setvar4 title="M", pos={160,170},size={100,25}, fSize=13, value=U_prefactor_m, limits={0,inf,0.01}, proc=VarProcYMultiply
	SetVariable setvar5 title="S ", pos={160,190},size={100,25}, fSize=13, value=U_prefactor_s, limits={0,inf,0.01}, proc=VarProcYMultiply
//	CheckBox long_cb title="",pos={50,140},value=1,fSize=13, variable=root:Red2Dpackage:U_Lcb, proc=CheckProcYMultiply
//	CheckBox mid_cb title="",pos={50,160},value=1,fSize=13, variable=root:Red2Dpackage:U_Mcb, proc=CheckProcYMultiply
//	CheckBox short_cb title="",pos={50,180},value=1,fSize=13, variable=root:Red2Dpackage:U_Scb, proc=CheckProcYMultiply
	SetVariable setvar6 title="L-M ", pos={330,150},size={100,25}, fSize=13, value=U_Cursorlong, limits={0,inf,1}, proc=VarProcCursor
	SetVariable setvar7 title="M-S", pos={330,170},size={100,25}, fSize=13, value=U_Cursormid, limits={0,inf,1}, proc=VarProcCursor
	SetVariable setvar8 title="Output name", pos={20,225},size={550,25}, fSize=13, value=root:Red2Dpackage:U_OutputName
	Button button0 title="Display",size={120,23},pos={120,260}, proc=ButtonProc_DisplayWavesToBeCombined
	Button button1 title="Combine",size={120,23},pos={340,260}, proc=ButtonProc_CombineWavesOfdifferentSDD
	TitleBox title3 title="If you have only two waves to combine,  leave the Short SDD column empty.",pos={90,100},frame=0,fSize=13, fColor=(65535,0,0)

End

Function ButtonProc_DisplayWavesToBeCombined(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			//Get references of int, q and err waves
			SVAR LongSDDIntPath = root:Red2Dpackage:U_LongSDDIntPath
			SVAR midSDDIntPath = root:Red2Dpackage:U_midSDDIntPath
			SVAR ShortSDDIntPath = root:Red2Dpackage:U_ShortSDDIntPath
			String long_qpath = RemoveEnding(LongSDDIntPath, "_i") + "_q"
			String mid_qpath = RemoveEnding(midSDDIntPath, "_i") + "_q"
			String short_qpath = RemoveEnding(ShortSDDIntPath, "_i") + "_q"
			String long_errPath = RemoveEnding(LongSDDIntPath, "_i") + "_s"
			String mid_errpath = RemoveEnding(midSDDIntPath, "_i") + "_s"
			String short_errPath = RemoveEnding(ShortSDDIntPath, "_i") + "_s"
			
			Wave/Z I_long = $LongSDDIntPath
			Wave/Z I_mid = $midSDDIntPath
			Wave/Z I_short = $ShortSDDIntPath
			Wave/Z q_long = $long_qpath
			Wave/Z q_mid = $mid_qpath
			Wave/Z q_short = $short_qpath
			Wave/Z err_long = $long_errPath
			Wave/Z err_mid = $mid_errPath
			Wave/Z err_short = $short_errPath
			
			//Create a graph
			DoWindow/F CombineTest // Check if there is a window named 2DImageWindow. Exist returns 1 else 0.	
			If(V_flag == 0) // Create a new image window with name as 2DImageWindow if not exists.
				Display/k=1/N=CombineTest I_long vs q_long
				AppendToGraph/W=CombineTest I_mid vs q_mid
				If(WaveExists(I_short))
					AppendToGraph/W=CombineTest I_short vs q_short
				Endif
			Else // Replace selected waves on the window
				
				String TL = TraceNameList("CombineTest", ";", 1)
				Variable numInTraceLst = ItemsInList(TL)
				Variable i
				For(i=0; i<numInTraceLst; i++)
					RemovefromGraph/W=CombineTest $StringFromList(numInTraceLst-i-1, TL) //Remove traces inversly to avoid errors.
				Endfor
				AppendToGraph/W=CombineTest I_long vs q_long
				AppendToGraph/W=CombineTest I_mid vs q_mid
				If(WaveExists(I_short))
					AppendToGraph/W=CombineTest I_short vs q_short
				Endif
			Endif
			
			//Add error bars
			Dowindow/F CombineTest // Activate window ImageGraph
			String TraNamLst = TraceNameList("", ";", 1)
			Variable NumTraces = ItemsInList(TraNamLst)
			String TraceName, TracePath, ErrPath
			For(i=0; i < NumTraces; i++)
				TraceName = StringFromList(i, TraNamLst)
				TracePath = GetWavesDataFolder(TraceNameToWaveRef("",TraceName), 2) // I use this complicated method because I need the full path to identify err wave.
				ErrPath = RemoveEnding(TracePath, "_i")  + "_s"
				If(WaveExists($ErrPath)==0)
					Print "No error bar wave for " + TraceName
				Else
					ErrorBars $TraceName SHADE= {0,0,(0,0,0,0),(0,0,0,0)},wave=($ErrPath,$ErrPath)
				Endif
			Endfor
			
			//Modify graph
			Legend/C/F=0/B=1/N=text0 ""
			Label left "\\f02I\\f00 [-]"
			Label bottom "\\f02q\\f00 [Å\\S−1\\M]"	
			ModifyGraph log=1, tick=2, mirror=1, axThick=1, lsize=1
			TraceName = StringFromList(0, TraNamLst)
			ModifyGraph rgb($TraceName)=(65535,0,0)
			TraceName = StringFromList(1, TraNamLst)
			ModifyGraph rgb($TraceName)=(20000,65535,20000)
			If(WaveExists(I_short))
				TraceName = StringFromList(2, TraNamLst)
				ModifyGraph rgb($TraceName)=(0,0,65535)
			Endif
			
			ModifyGraph mode=4, marker=8, opaque=1
			
			DoYMultiplier("CombineTest")  // update Y-multiplier
			UpdateCursor("CombineTest")  // update cursors
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProc_CombineWavesOfdifferentSDD(ba) : ButtonControl //Combine waves
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			// Bring the window to front
			Dowindow/F CombineTest
			
			//Get references of int, q and err waves
			SVAR LongSDDIntPath = root:Red2Dpackage:U_LongSDDIntPath
			SVAR midSDDIntPath = root:Red2Dpackage:U_midSDDIntPath
			SVAR ShortSDDIntPath = root:Red2Dpackage:U_ShortSDDIntPath
			String long_qpath = RemoveEnding(LongSDDIntPath, "_i") + "_q"
			String mid_qpath = RemoveEnding(midSDDIntPath, "_i") + "_q"
			String short_qpath = RemoveEnding(ShortSDDIntPath, "_i") + "_q"
			String long_errPath = RemoveEnding(LongSDDIntPath, "_i") + "_s"
			String mid_errpath = RemoveEnding(midSDDIntPath, "_i") + "_s"
			String short_errPath = RemoveEnding(ShortSDDIntPath, "_i") + "_s"
			
			Wave/Z I_long = $LongSDDIntPath
			Wave/Z I_mid = $midSDDIntPath
			Wave/Z I_short = $ShortSDDIntPath
			Wave/Z q_long = $long_qpath
			Wave/Z q_mid = $mid_qpath
			Wave/Z q_short = $short_qpath
			Wave/Z s_long = $long_errPath
			Wave/Z s_mid = $mid_errPath
			Wave/Z s_short = $short_errPath
			
			NVAR qindex_0 = root:Red2Dpackage:U_qindex_0
			NVAR qindex_1 = root:Red2Dpackage:U_qindex_1
			NVAR qindex_2 = root:Red2Dpackage:U_qindex_2
			NVAR qindex_3 = root:Red2Dpackage:U_qindex_3			
			NVAR prefactor_l = root:Red2Dpackage:U_prefactor_l
			NVAR prefactor_m = root:Red2Dpackage:U_prefactor_m
			NVAR prefactor_s = root:Red2Dpackage:U_prefactor_s
			SVAR OutputName = root:Red2Dpackage:U_OutputName
			
			string ModOutputName = CleanupName(OutputName, 0)
			String Output_i_path = "root:SDD_combined:" + ModOutputName + "_i"
			String Output_q_path = "root:SDD_combined:" + ModOutputName + "_q"
			String Output_s_path = "root:SDD_combined:" + ModOutputName + "_s"
			
			//Trim and concatenate waves 
			//Int

			If(WaveExists(I_short))
				Duplicate/FREE/O/R=[,qindex_0] I_long ref_I_long
				Duplicate/FREE/O/R=[qindex_1,qindex_2] I_mid ref_I_mid
				Duplicate/FREE/O/R=[qindex_3,] I_short ref_I_short
				ref_I_long *= prefactor_l
				ref_I_mid *= prefactor_m
				ref_I_short *= prefactor_s
				Concatenate/O {ref_I_long, ref_I_mid, ref_I_short}, $Output_i_path
			Else
				Duplicate/FREE/O/R=[,qindex_0] I_long ref_I_long
				Duplicate/FREE/O/R=[qindex_1,] I_mid ref_I_mid
				ref_I_long *= prefactor_l
				ref_I_mid *= prefactor_m
				Concatenate/O {ref_I_long, ref_I_mid}, $Output_i_path
			Endif
			
			//q
			If(WaveExists(I_short))
				Duplicate/FREE/O/R=[,qindex_0] q_long ref_q_long
				Duplicate/FREE/O/R=[qindex_1,qindex_2] q_mid ref_q_mid
				Duplicate/FREE/O/R=[qindex_3,] q_short ref_q_short
				Concatenate/O {ref_q_long, ref_q_mid, ref_q_short}, $Output_q_path
			Else
				Duplicate/FREE/O/R=[,qindex_0] q_long ref_q_long
				Duplicate/FREE/O/R=[qindex_1,] q_mid ref_q_mid
				Concatenate/O {ref_q_long, ref_q_mid}, $Output_q_path
			Endif
				
			//err
			If(WaveExists(I_short))
				Duplicate/FREE/O/R=[,qindex_0] s_long ref_s_long
				Duplicate/FREE/O/R=[qindex_1,qindex_2] s_mid ref_s_mid
				Duplicate/FREE/O/R=[qindex_3,] s_short ref_s_short
				ref_s_long *= prefactor_l
				ref_s_mid *= prefactor_m
				ref_s_short *= prefactor_s
				Concatenate/O {ref_s_long, ref_s_mid, ref_s_short}, $Output_s_path
			Else
				Duplicate/FREE/O/R=[,qindex_0] s_long ref_s_long
				Duplicate/FREE/O/R=[qindex_1,] s_mid ref_s_mid
				ref_s_long *= prefactor_l
				ref_s_mid *= prefactor_m
				Concatenate/O {ref_s_long, ref_s_mid}, $Output_s_path
			Endif
			
			//Check if trace already exist. Then append to graph if trace does not exist
			String TraceLst = TraceNameList("CombineTest",";",1)
			Variable NumTraces = itemsInList(TraceLst)
			variable i, ext
			String TraceName, TracePath
			For(i=0; i<NumTraces; i++)
				TraceName = StringFromList(i, TraceLst)
				TracePath = GetWavesDataFolder(TraceNameToWaveRef("CombineTest",TraceName),2)
				If(StringMatch(Output_i_path, TracePath) == 1)
					ext ++
				Endif
			Endfor

			If(ext == 0)
				//Append combined waves
				AppendToGraph/W=CombineTest $Output_i_path vs $Output_q_path
				//Add error bars
				TraceLst = TraceNameList("CombineTest",";",1)
				NumTraces = itemsInList(TraceLst)
				TraceName = StringFromList(NumTraces-1, TraceLst)
				If(WaveExists($Output_s_path)==0)
					Print "No error bar wave for " + TraceName
				Else
					ErrorBars $TraceName SHADE= {0,0,(0,0,0,0),(0,0,0,0)},wave=($Output_s_path,$Output_s_path)
				Endif
			Endif
				
			ModifyGraph rgb($TraceName)=(16385,65535,65535)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function VarProcYMultiply(sva) : SetVariableControl //Set Y multiplier
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			DoYMultiplier("CombineTest")			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Static Function DoYMultiplier(WindowName)
	String WindowName
	
	SVAR ShortSDDIntPath = root:Red2Dpackage:U_ShortSDDIntPath
	Wave/Z I_short = $ShortSDDIntPath
	NVAR prefactor_l = root:Red2Dpackage:U_prefactor_l
	NVAR prefactor_m = root:Red2Dpackage:U_prefactor_m
	NVAR prefactor_s = root:Red2Dpackage:U_prefactor_s

	Dowindow/F $WindowName // Activate window ImageGraph
	String TraNamLst = TraceNameList("", ";", 1)
	Variable NumTraces = ItemsInList(TraNamLst)
	String TraceName_long
	String TraceName_mid
	String TraceName_short
	If(WaveExists(I_short))
		TraceName_long = StringFromList(NumTraces-3, TraNamLst)
		TraceName_mid = StringFromList(NumTraces-2, TraNamLst)
		TraceName_short = StringFromList(NumTraces-1, TraNamLst)
		ModifyGraph muloffset($TraceName_long)={0,prefactor_l}
		ModifyGraph muloffset($TraceName_mid)={0,prefactor_m}
		ModifyGraph muloffset($TraceName_short)={0,prefactor_s}
	Else
		TraceName_long = StringFromList(NumTraces-2, TraNamLst)
		TraceName_mid = StringFromList(NumTraces-1, TraNamLst)
		ModifyGraph muloffset($TraceName_long)={0,prefactor_l}
		ModifyGraph muloffset($TraceName_mid)={0,prefactor_m}
	Endif

End

Function CheckProcYMultiply(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function VarProcCursor(sva) : SetVariableControl // Cursor related
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			UpdateCursor("CombineTest")
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Static Function UpdateCursor(WindowName)
	String WindowName
			//Get info from package datafolder
			Dowindow/F $WindowName
			
			SVAR LongSDDIntPath = root:Red2Dpackage:U_LongSDDIntPath
			SVAR midSDDIntPath = root:Red2Dpackage:U_midSDDIntPath
			SVAR ShortSDDIntPath = root:Red2Dpackage:U_ShortSDDIntPath
			String long_qpath = RemoveEnding(LongSDDIntPath, "_i") + "_q"
			String mid_qpath = RemoveEnding(midSDDIntPath, "_i") + "_q"
			String short_qpath = RemoveEnding(ShortSDDIntPath, "_i") + "_q"
			String long_errPath = RemoveEnding(LongSDDIntPath, "_i") + "_s"
			String mid_errpath = RemoveEnding(midSDDIntPath, "_i") + "_s"
			String short_errPath = RemoveEnding(ShortSDDIntPath, "_i") + "_s"
			
			Wave/Z I_long = $LongSDDIntPath
			Wave/Z I_mid = $midSDDIntPath
			Wave/Z I_short = $ShortSDDIntPath
			Wave/Z q_long = $long_qpath
			Wave/Z q_mid = $mid_qpath
			Wave/Z q_short = $short_qpath
			Wave/Z err_long = $long_errPath
			Wave/Z err_mid = $mid_errPath
			Wave/Z err_short = $short_errPath

			NVAR qindex_0 = root:Red2Dpackage:U_qindex_0
			NVAR qindex_1 = root:Red2Dpackage:U_qindex_1
			NVAR qindex_2 = root:Red2Dpackage:U_qindex_2
			NVAR qindex_3 = root:Red2Dpackage:U_qindex_3
			
			NVAR U_Cursorlong = root:Red2Dpackage:U_Cursorlong
			NVAR U_Cursormid = root:Red2Dpackage:U_Cursormid

			//Get trace name and the selected q index
			String TraNamLst = TraceNameList("", ";", 1)
			Variable NumTraces = ItemsInList(TraNamLst)
			String TraceName_long
			String TraceName_mid
			String TraceName_short
			If(WaveExists(I_short))
				TraceName_long = StringFromList(NumTraces-3, TraNamLst)
				TraceName_mid = StringFromList(NumTraces-2, TraNamLst)
				TraceName_short = StringFromList(NumTraces-1, TraNamLst)
			Else
				TraceName_long = StringFromList(NumTraces-2, TraNamLst)
				TraceName_mid = StringFromList(NumTraces-1, TraNamLst)
			Endif
			
			
			// Long and middle
			//Use cursor to set q index and value of mid SDD
			qindex_0 = U_Cursorlong	// get value from panel
			Cursor/W=$WindowName A $TraceName_long qindex_0		// set cursor
			Variable qval_long = q_long[qindex_0]	// get q value
			
			//Find nearest q index of long SDD
			Variable qTol = qval_long*0.00001
			FindValue/V=(qval_long) /T=(qTol) q_mid
			Variable i
			For(i=0; i<1000; i++)
				If(V_value==-1)
					qTol*=(i+1)
					FindValue/V=(qval_long) /T=(qTol) q_mid 
				Endif
			Endfor
			
			If(V_value == -1) //No nearest value found
				Abort "Neast q value was not found."
			Else
				qindex_1 = V_value
			Endif
			
			Do
				qindex_1 +=1
				if(q_long[qindex_0] < q_mid[qindex_1])
					break
				Endif
			While(1)

			Cursor/W=$WindowName B $TraceName_mid qindex_1
			
		If(WaveExists(I_short))
			// Middle and short
			//Use cursor to set q index and value of mid SDD
			qindex_2 = U_Cursormid	// get value from panel
			Cursor/W=$WindowName C $TraceName_mid qindex_2		// set cursor
			Variable qval_mid = q_mid[qindex_2]	// get q value
			
			//Find nearest q index of long SDD
			qTol = qval_mid*0.0000001
			FindValue/V=(qval_mid) /T=(qTol) q_short
			For(i=0; i<1000; i++)
				If(V_value==-1)
					qTol*=(i+1)
					FindValue/V=(qval_mid) /T=(qTol) q_short
				Endif
			Endfor
			
			If(V_value == -1) //No nearest value found
				Abort "Neast q value was not found."
			Else
				qindex_3 = V_value
			Endif
			
			Do
				qindex_3 +=1
				if(q_mid[qindex_2] < q_short[qindex_3])
					break
				Endif
			While(1)

			Cursor/W=$WindowName D $TraceName_short qindex_3
		Endif
			
		Cursor /M/C=(60000,0,0)/S=1 A
		Cursor /M/C=(0,0,60000)/S=1 B
		Cursor /M/C=(60000,0,0)/S=1 C
		Cursor /M/C=(0,0,60000)/S=1 D
End

// *************************
// Shorten 1D scattering profiles
// *************************
Function R2D_Shorten1D()
	
	/////Check error
	If(R2D_Error_1Dexist() == -1)
		Abort
	Endif
	
	/////////////////////GET 1D WAVELIST TO Delete/////////////////////
	String List1D = WaveList("*", ";", "TEXT:0" )	
	Variable numOf1D = ItemsInList(List1D,";")
	Wave refwave = $StringFromList(0, List1D)
	
	
	///////////////TYPE CORRECTION FACTOR///////////////
	Variable FirstPt, LastPt
	FirstPt = 0
	LastPt = DimSize(refwave,0)
	Prompt FirstPt, "Enter first point: "
	Prompt LastPt, "Enter last point: "
	DoPrompt "Shorten all 1D waves in current datafolder", FirstPt, LastPt
	if (V_Flag)
		Print "User canceled"
		return -1		// User canceled
	endif
	
	if (LastPt <= FirstPt)
		Print "Proceddure aborted"
		Abort "Proceddure aborted. Last point must be larger than the first point."
	elseif (FirstPt < 0 || LastPt < 0)
		Print "Proceddure aborted"
		Abort "Proceddure aborted. Negative value is not acceptable."
	endif
	
	////////Delete Points////////
	variable i
	For(i=0;i<numOf1D; i+=1)
		
		/// Get target name from targetlist and remove the unncessary symbols.
		Wave Wave1D = $StringFromList(i, List1D)
		DeletePoints LastPt, DimSize(Wave1D,0)-LastPt+1, Wave1D
		DeletePoints 0, FirstPt, Wave1D
		
	Endfor

End

// *************************
// Resampling 1D scattering profiles
// *************************
Function R2D_LogResample1D()
	/////Check error
	If(R2D_Error_1Dexist() == -1)
		Abort
	Endif
	
	// Let user input a base and select a Resample mode
	String mode = StrVarOrDefault("::Red2Dpackage:U_mode", "Resample")
	variable base = NumVarOrDefault("::Red2Dpackage:U_base",1.05)
	Prompt mode, "Resample mode",popup,"Resample;Bin"
	Prompt base, "Enetr a base value for for new index j (e.g. j = base^i )"
	DoPrompt "Resample info" mode, base
	if(V_Flag)
		Print "User canceled"
		Abort
	Elseif(base <= 1)
		Print "Base must be a value larger than 1"
		Abort "Base must be a value larger than 1"
	endif
	
	String/G ::Red2Dpackage:U_mode = mode
	Variable/G ::Red2Dpackage:U_base = base
	
	// Set a new datafolder to save resampled data
	String ResDFpath = "::Log" + mode + "_" + GetDataFolder(0)
	NewDataFolder/O $ResDFpath
	
	// GetWavelist in current datafolder
	String keyword
	String keyword_list = "*_q;*_i;*_s;*_2t"
	String reflist
	Variable numInList
	String tempName
	String newWavePath
	
	// Call Resample code
	Variable i, j
	For(i=0; i<4; i++)
		keyword = StringFromList(i, keyword_list)
		reflist = Wavelist(keyword,";","DIMS:1,TEXT:0")
		numInList = itemsInList(reflist)
		If(cmpstr(keyword, "*_s") == 0)	// if true, use error propagation
			For(j=0; j<numInList; j++)
				Wave/Z refWave = $StringFromList(j, reflist)
				tempName = LogResample(mode, base, refWave, 1)
				newWavePath = ResDFpath + ":" + NameOfWave(refWave)
				Duplicate/O/D $tempName, $newWavePath
				Killwaves $tempName
			Endfor
		Else	// if false, use normal Resample
			For(j=0; j<numInList; j++)
				Wave/Z refWave = $StringFromList(j, reflist)
				tempName = LogResample(mode, base, refWave, 0)
				newWavePath = ResDFpath + ":" + NameOfWave(refWave)
				Duplicate/O/D $tempName, $newWavePath
				Killwaves $tempName
			Endfor
		Endif	
	Endfor
	
End

Static Function/S LogResample(mode, base, pWave, err)
	String mode	// Resample or Bin, specified by resamp and bin
	variable base	// the base of log spacing
	wave pWave	// target wave
	variable err	// 0 for normal, 1 for error propagation
	
	Variable numPts = DimSize(pWave,0)	// Get Dimsize of target wave
	Duplicate/O/D/FREE pWave, errWave2
	errWave2 = pWave^2
	
	// log spacing data
	variable i, j, i0
	i = 0	// initialize
	j = 0	// initialize
	i0 = 0	// initialize
	Make/FREE/O/N=(numPts) refwave	// a reference wave to store the log spaced data
	//	The first point will not be binned or resampled.
	refwave[0] = pWave[0]	// i = round(base^j) - 1 = 0 when j = 0
	
	Do
		j ++	// Index of log spaced wave
		i = round(base^j) - 1	// the corresponding index of original wave
	
		If(i >= numPts)	// if the index is outside the wave, break loop
			break
		Endif
		
		If(i == i0)	// if the current index is equal to the previous one, then skip
			refwave[j] = NaN
		Else
			Strswitch(mode)
				Case "Bin":
						If(err == 0)
							refwave[j] = mean(pWave, pnt2x(pWave,i0+1),pnt2x(pWave,i)) 	// get an average
						Elseif(err == 1)
							refwave[j] = sqrt( sum(errWave2, pnt2x(pWave,i0+1),pnt2x(pWave,i)) )/ (i-i0)	// error propagation
						Endif
					break
				Case "Resample":
						refwave[j] = pWave[i]	// get log-spaced data. In Resample error wave, no need to use error propagation
					break
			Endswitch
		Endif
		
		i0 = i	// store the old index of original wave	
	While(1)
	
	// save data
	String NewName
	Strswitch(mode)
		case "Bin":
			NewName = NameOfWave(pWave) + "_logbin"
			break
		Case "Resample":
			NewName = NameOfWave(pWave) + "_logsamp"
			break
	endswitch
	Make/O/D/N=(j) $NewName
	wave NewWave = $NewName
	NewWave = refwave	// save refwave to a shorter new wave to remove unnecessary points
	//	Wavetransform/O zapNaNs NewWave	// remove NaN from waves
	
	Return NewName

End

// *************************
// Export 1D scattering profiles
// *************************
Function R2D_Export1D(WhichName, xaxis)
	Variable WhichName	//0 for wave name, 1 for sample name.
	Variable xaxis  //0 for q, 1 for 2 theta.

	// Check if int data exist. If not, abort the process
	If(	R2D_Error_1Dexist() == -1)
		Abort
	Endif
	
//	String Intlst = WaveList("*_i", ";","DIMS:1,TEXT:0") //return a list of int in current datafolder
	String Intlst = R2D_waveList_nofits("*_i")
	Variable numInLst = itemsinlist(Intlst)
		
	// Set a path to the folder to save files
	NewPath/O FolderPath	// Let user to select a symbolic path (i.e. folder) to save the files.
	
	If(V_flag == -1)
		Print "user cancelled"
		return -1
	Endif
	Pathinfo/S FolderPath	// Set prest path to the selected folder. This is not necessary.
	
	// Prepare for saving
	String WaveNam
	String SampleName
	String filename
	String header0
	String header1
	String DatafolderPath = GetDataFolder(1)
	String pxpName = IgorInfo(1) + ".pxp"
	Variable refnum = 0
	String PackagePath = GetDataFolder(1)+":Red2Dpackage:"
	Wave/T datasheet = $(PackagePath + "Datasheet")
	NVAR/Z Wavelength = ::Red2Dpackage:U_Lambda
	NVAR/Z SDD = ::Red2Dpackage:U_SDD
	String Trans
	
	header0 = "This file was generated by Red2D (https://github.com/hurxl/Red2D).\r"
	header0 += "Date&time: " + Secs2Date(DateTime,-2) + " " + time() + "\r"
	
	Variable i
	
	// Create a txt file and append a header
	For(i=0; i < numInLst; i++)

		WaveNam = RemoveEnding( StringFromList(i, Intlst), "_i")	// Get wave name
		SampleName = WaveNam  // default value
		Trans = "NaN"  // default value
		
		// if datasheet exist, get trans and sample name of the corresponding 1D wave.
		If(WaveExists(datasheet)==1)
			Make/FREE/T/O/N=(DimSize(Datasheet,0)) ImageName = Datasheet[p][%ImageName]
			FindValue/TEXT=(WaveNam) ImageName  // get the index of the corresponding ImageName
			
			If(V_value != -1) // if the imagename was found, use datasheet info. Otherwise, use defualt. V_value stores the index from FindValue	
				Trans = Datasheet[V_value][%Trans]  // get trans
				If(FindDimLabel(Datasheet, 1, "SampleName") != -2)  // if there is a column, SampleName, then use the datasheet info.  Otherwise, use defualt.
					SampleName = Datasheet[V_value][%SampleName]
				Endif
			Endif

		Endif
		
		header1 = ""	// Clear the content in header1 from previous loop
		header1 += "Experiment name: " + pxpName +"\r"
		header1 += "Datafolder path: " + DatafolderPath + "\r"
		header1 += "Sample name: " + SampleName + "\r"
		header1 += "Wave name: " + WaveNam + "\r"
		header1 += "SDD: " + num2str(SDD) +"m \r"
		header1 += "Wavelength : " + num2Str(Wavelength) + "A \r"
		header1 += "Transmittance: " + Trans +"\r"


		
		// Set file name
		Switch(WhichName)
			Case 1:
				If(Strlen(SampleName) == 0)	// if sample name does not exist, use image name
					filename = WaveNam + ".txt"
				Else
					filename = SampleName + ".txt" //	set file name
				Endif
				break
			
			default:
				filename = WaveNam + ".txt" //	set file name
				break
		Endswitch
		
		Close/A
		Open/P=FolderPath refnum as filename	// Write a header
		fprintf refnum, "%s", header0
		fprintf refnum, "%s", header1
		Close refnum
		
		if(xaxis == 0)
			Duplicate/O/D $(WaveNam + "_q"), q_A
		elseif(xaxis == 1)
			Duplicate/O/D $(WaveNam + "_2t"), TwoTheta
		endif
		Duplicate/O/D $(WaveNam + "_i"), I_cm
		Duplicate/O/D $(WaveNam + "_s"), s_cm
		
		If(xaxis == 0)
			Save/A/G/W/P=FolderPath q_A, I_cm, s_cm as filename	// save seletected waves in a txt file as filename in folderpath.		
		Else
			Save/A/G/W/P=FolderPath TwoTheta, I_cm, s_cm as filename	// save seletected waves in a txt file as filename in folderpath.			
		Endif
		
	Endfor

	KillWaves/Z q_A, TwoTheta, I_cm, s_cm

End

// *************************
// Load 1D profiles. q, i, s.
// *************************
Function/S R2D_LoadSelectedQIS()

	Variable refNum
	String message = "Select one or more files"
	String outputPaths
	String fileFilters = "Data Files (*.txt,*.asc,*.dat,*.csv):.txt,.asc,.dat,.csv;"
	fileFilters += "All Files:.*;"

	Open /D /R /MULT=1 /F=fileFilters /M=message refNum
	outputPaths = S_fileName //"open" automatically store the selected path as list in S_fileName
	
	string path
	string filename
	string newname
	variable numOfWaves
	string buffer = ""
	string header = ""
	if (strlen(outputPaths) == 0)
		Print "Cancelled"
	else
		Variable numFilesSelected = ItemsInList(outputPaths, "\r")
		Variable i, j, k
		for(i=0; i<numFilesSelected; i++)
			path = StringFromList(i, outputPaths, "\r")
			filename = ParseFilePath(3, path, ":", 0, 0) //Get filename from path without extension
			newname = CleanupName(filename, 0)
			
			// Read header. If the first character of the line is number and it repeats for three times. Regard it as the data.
			j = 0
			k = 0
			Open/R refnum as path
			Do
				if(k>3)	// if  more than three rows starting with a number
					break
				endif
				FReadLine refnum, buffer
				if(numtype(str2num(buffer)) == 0)	// if it is a number
					k++
				else
					header += buffer
				endif
				j++
			While(j<100)
			
			Loadwave/O/G/Q/N=LoadedWave path
			numOfWaves = itemsInList(S_WaveNames)
			if(numOfWaves == 2)
				wave qwave = $StringFromList(0, S_WaveNames)
				wave iwave = $StringFromList(1, S_WaveNames)
				Note/K qwave, header
				Note/K iwave, header
				Duplicate/O qwave $(newname+"_q")
				Duplicate/O iwave $(newname+"_i")
			elseif(numOfWaves == 3)
				wave qwave = $StringFromList(0, S_WaveNames)
				wave iwave = $StringFromList(1, S_WaveNames)
				wave swave = $StringFromList(2, S_WaveNames)
				Note/K qwave, header
				Note/K iwave, header
				Note/K swave, header
				Duplicate/O qwave $(newname+"_q")
				Duplicate/O iwave $(newname+"_i")
				Duplicate/O swave $(newname+"_s")
			else
				Print filename + " is not loaded."
			endif

		endfor // i
	endif

	Killwaves qwave, iwave, swave
	return outputPaths		// Will be empty if user canceled

End

// *************************
// Add 1D waves. Not in use 2023-04-16.
// *************************
Function R2D_Add1D(filtername, interval)
	string filtername
	variable interval  // inverval to add, 10 -> add every 10-waves
	
	// get a wavelist in current datafolder
	string IntList = WaveList("*_i", ";","DIMS:1,TEXT:0") //return a list of int in current datafolder
	IntList = R2D_skip_fit(IntList)
	IntList = ListMatch(IntList, "*"+filtername+"*")
	If(strlen(IntList) == 0)
		Abort "No items match. Use * as a wildcard and try again."
	Endif
	
	// Create a new datafolder to save output
	string newDFpath = "::"+GetDataFolder(0)+"_added"
	NewDataFolder/O $newDFpath

	// prepare _i, _q, _s, _2t waves
	string intwname0 = StringFromList(0,IntList)
	wave qwave = $R2D_Assign_Xwaves(intwname0, "_q")
	wave t2wave = $R2D_Assign_Xwaves(intwname0, "_2t")
	string newqwavepath
	string new2twavepath
	string newIntwavepath 
	string newErrwavepath
	
	variable numInlist = itemsInList(IntList)
	variable i, j, k
	i =0; j =0; k = 0
	Do
		j = 0 // rest j for each large while loop
		
		newIntwavepath = newDFpath+":"+filtername+"_"+num2str(k)+"_i"
		newErrwavepath = newDFpath+":"+filtername+"_"+num2str(k)+"_s"
		newqwavepath = newDFpath+":"+filtername+"_"+num2str(k)+"_q"
		new2twavepath = newDFpath+":"+filtername+"_"+num2str(k)+"_2t"
		Duplicate/O/D $intwname0, $newIntwavepath, $newErrwavepath
		Duplicate/O/D qwave, $newqwavepath
		Duplicate/O/D t2wave, $new2twavepath
		Wave intensity = $newIntwavepath
		Wave err = $newErrwavepath
		intensity = 0  // initialize
		err = 0  // initialize
		
		Do
			wave/Z tempInt = $StringFromList(i, IntList)
			wave/Z temperr = $(RemoveEnding(StringFromList(i, IntList), "_i") + "_s")
			If(!WaveExists(tempInt))
				Print "Wave number " + num2str(i) + " does not exist."
				break
			Endif
			intensity += tempInt
			err += temperr^2  // error propagation
			i++
			j++
		While(j < interval)
		
		// normalze the added waves
		intensity /= j
		err = sqrt(err)/j
		
		k++ // count the number of large while loop
		
	While(i < numInlist)

End

// *** Simple Match Operation (1D)
// 2024-06-01 GUI only. Tested.
Function R2D_simple_math_operation_1D(operation, matchStr, OperationValue)
	string operation // type of the math operation: add, subtract, multiply and divide
	string matchStr
	variable OperationValue

	//////ERROR CHECKER///////
	If(R2D_Error_1Dexist() == -1)
		Abort
//	Elseif(R2D_Error_DatasheetExist1D() == -1)
//		Abort
//	Elseif(R2D_Error_DatasheetMatch1D() == -1)
//		Abort
	Endif

	matchStr += "_i"
	string IntList = WaveList(matchStr, ";","DIMS:1,TEXT:0") //return a list of int in current datafolder
	variable numOf1D = ItemsInList(IntList)
	String targetName
	variable i
	For(i=0;i<numOf1D; i+=1)
		//Get target name from targetlist and remove the unncessary symbols
		targetName = RemoveEnding(StringFromList(i, IntList), "_i")
		Wave Wave1D = $(targetName + "_i")
		Wave Wave1D_s = $(targetName + "_s")

		//Do the operation
		strswitch(operation)
			case "add":
				Wave1D += OperationValue
				Wave1D_s += OperationValue
				break
			case "subtract":
				Wave1D -= OperationValue
				Wave1D_s -= OperationValue
				break
			case "multiply":
				Wave1D *= OperationValue
				Wave1D_s *= OperationValue
				break
			case "divide":
				Wave1D /= OperationValue
				Wave1D_s /= OperationValue
				break
		endswitch
	Endfor
	
End