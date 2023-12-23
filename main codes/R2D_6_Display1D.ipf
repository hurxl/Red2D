#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/////////DISPLAY 1D GRAPH///////////
Function R2D_Display1D(new, xx, [winNam, IntList])
	variable new, xx  // new = 0, new graph; new = 1, append to existing graph; xx = 0, q; xx = 1, 2theta; xx = 2, p
	string winNam, IntList
	
	//////ERROR CHECKER////
	If(R2D_Error_1Dexist() == -1)
		Abort
	Endif
	///////////////////////
	
	/// Check if specified winNam exists
	variable ww = 0  // a boolen to show if the specified window name exists.
	If(!ParamIsDefault(winNam))
		DoWindow $winNam
		If(V_flag != 0)  // the window exist
			ww = 1  // the window exist
		Endif
	Endif
	
	/// Create an IntList in current datafolder
	If(ParamIsDefault(IntList))  // if IntList is not specified
		IntList = WaveList("*_i", ";","DIMS:1,TEXT:0") //return a list of int in current datafolder
		IntList = R2D_skip_fit(IntList)
	Else
	// if IntLsit is specified, then use the Intlist
	Endif
	Variable numOfInt = itemsinlist(IntList)

	String targetPath_i, targetPath_x, targetPath_q, targetPath_2t
	String CDF = GetDataFolder(1)
	
	/// Create a graph and display a trace
	variable i = 0
	If(new == 0) //create new graph
		
		/// set y and x waves
		targetPath_i = CDF + StringFromList(0, IntList) // Get full path of targt Name
		targetPath_x = R2D_Assign_Xwaves(targetPath_i, xx) //2021-05-19(i, targetPath_i, xx) -> (targetPath_i, xx)
		
		/// display the first trace
		If(ParamIsDefault(winNam))  // if window name is not specified
			Display $targetPath_i vs $targetPath_x
		Else  // if the window name is specified
			KillWindow/Z $winNam  // if the window name is used, kill the window of the specified name
			Display/N=$winNam $targetPath_i vs $targetPath_x
		Endif
		
		/// append the others
		For(i = 1; i < numOfInt; i++)
			targetPath_i = CDF + StringFromList(i, IntList)
			targetPath_x = R2D_Assign_Xwaves(targetPath_i, xx)
			AppendToGraph $targetPath_i vs $targetPath_x
		Endfor			
		
		/// add axis labels and legend
		If(xx == 0) //Display int vs qq
			Legend/C/F=0/B=1/N=text0 ""
			Label left "\\f02I\\f00 (-)"
			Label bottom "\\f02q\\f00 (Å\\S−1\\M)"	
			ModifyGraph log=1, tick=2, mirror=1, axThick=1, lsize=1
		Elseif(xx == 1)
			Legend/C/F=0/B=1/N=text0 ""
			Label left "\\f02I\\f00 (-)"
			Label bottom "2\\f02θ\\f00 (deg)"
			ModifyGraph log(left)=1, tick=2, mirror=1, axThick=1, lsize=1
		Elseif(xx == 2)
			Legend/C/F=0/B=1/N=text0 ""
			Label left "\\f02I\\f00 (-)"
			Label bottom "\\f02p\\f00"
			ModifyGraph log=1, tick=2, mirror=1, axThick=1, lsize=1
		Endif
		
		if(Exists("Publication_Style") == 6)
			Publication_Style()
		endif
		
	Else // append 1d
			
		For(i = 0; i < numOfInt; i++)		
			/// set y and x waves
			targetPath_i = CDF + StringFromList(i, IntList)
			targetPath_x = R2D_Assign_Xwaves(targetPath_i, xx)
			
			/// append traces to graph
			If(ParamIsDefault(winNam))  // if window name is not specified
				AppendToGraph $targetPath_i vs $targetPath_x
			Else  // if the window name is specified
				AppendToGraph/W=$winNam $targetPath_i vs $targetPath_x
			Endif
			ModifyGraph lsize=1.5
		Endfor	
			
	Endif

	/// Add error bars
	String TraNamLst = TraceNameList("", ";", 1)
	TraNamLst =  R2D_skip_fit(TraNamLst)
	Variable NumTraces = ItemsInList(TraNamLst)
	String TraceName, ErrName
	For(i=0; i < NumTraces; i++)
		TraceName = StringFromList(i, TraNamLst)
		ErrName = RemoveEnding(GetWavesDataFolder(TraceNameToWaveRef("",TraceName), 2), "_i") + "_s"
		If(WaveExists($ErrName)==0)
			Print "No error bar wave for " + TraceName
		Else
			ErrorBars $TraceName SHADE= {0,0,(0,0,0,0),(0,0,0,0)},wave=($ErrName,$ErrName)
		Endif
	Endfor
	
End

Function/S R2D_Assign_Xwaves(targetPath_i, xx)
	string targetPath_i
	variable xx  // q or 2theta, corresponding to 0 and 1
	
	string targetPath_x
	If(xx == 0) //set x wave to q
		targetPath_x = RemoveEnding(targetPath_i, "_i") + "_q"
	Elseif(xx == 1) //set x wave to 2t
		targetPath_x = RemoveEnding(targetPath_i, "_i") + "_2t"
	Elseif(xx == 2) //set x wave to p
		targetPath_x = RemoveEnding(targetPath_i, "_i") + "_p"
	Endif

	return targetPath_x
End



