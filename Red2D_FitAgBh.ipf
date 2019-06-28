#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// Goal of this procedure:
/// Fit AgBe and get SDD and X0, Y0.

/////////////////////////////////////////////////
//////////////         GUI         //////////////
/////////////////////////////////////////////////

Function Red2D_CreAgBhPanel(refresh)
	variable refresh
	
	/// Check if in the Image folder
	If(Red2Dimagelistexist() != 0)
		Return -1
	Endif

	//////////Set Global variables//////////
	If(DatafolderExists("Red2DPackage")==0)
		NewDataFolder :Red2DPackage
	Endif

	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage

		Variable/G U_Xmax, U_Ymax, U_X0, U_Y0, U_SDD, U_Lambda, U_PixelSize, U_tiltX, U_tiltY, U_tiltZ, U_startR, U_endR, U_Vscan, U_Hscan, U_BKnoise
		// U_tiltZ is not in use. It is actuall X2. I use X-Y-X type rotation.
		U_Vscan = 1
		U_Hscan = 1
		
		If(U_startR == 0) 
			U_startR = 1
		Endif
		If(U_endR == 0)
			U_endR = 1
		Endif
	
	SetdataFolder saveDFR
	
	//////////Create a panel with buttons//////////
	If(refresh == 0)
	NewPanel/K=1/N=FitAgBeRings/W=(200,200,430,635)
	Endif
	
	SetVariable setvar0 title="X0 [pt]",pos={10,5},size={200,25},limits={-inf,inf,1},fSize=13, value=:Red2DPackage:U_X0, proc=UpdateAgBeRings
	SetVariable setvar1 title="Y0 [pt]",pos={10,30},size={200,25},limits={-inf,inf,1},fSize=13, value=:Red2DPackage:U_Y0, proc=UpdateAgBeRings
	SetVariable setvar2 title="SDD [m]",pos={10,55},size={200,25},limits={0,inf,0.001},fSize=13, value=:Red2DPackage:U_SDD, proc=UpdateAgBeRings
	SetVariable setvar3 title="Tilt_X [º]",pos={10,80},size={200,25},limits={-90,90,1},fSize=13, value=:Red2DPackage:U_tiltX, help={"-90 to 90º"}, proc=UpdateAgBeRings
	SetVariable setvar4 title="Tilt_Y [º]",pos={10,105},size={200,25},limits={-90,90,1},fSize=13, value=:Red2DPackage:U_tiltY, help={"-90 to 90º"}, proc=UpdateAgBeRings
	SetVariable setvar5 title="Lambda [A]",pos={10,130},size={200,25},limits={0,inf,0.1},fSize=13, value=:Red2DPackage:U_Lambda, help={"Cu = 1.5418A, Mo = 0.7107A"}, proc=UpdateAgBeRings
	SetVariable setvar6 title="Pixel Size [um]",pos={10,155},size={200,25},limits={0,inf,1},fSize=13, value=:Red2DPackage:U_PixelSize, help={"Pilatus = 172um, Eiger = 75um"}, proc=UpdateAgBeRings
	SetVariable setvar7 title="First ring to fit",pos={10,180},size={200,25},limits={1,11,1},fSize=13, value=:Red2DPackage:U_startR, proc=UpdateAgBeRings
	SetVariable setvar8 title="Last ring to fit",pos={10,205},size={200,25},limits={1,11,1},fSize=13, value=:Red2DPackage:U_endR, proc=UpdateAgBeRings
	SetVariable setvar9 title="Background Int",pos={10,230},size={200,25},limits={0,inf,100},fSize=13, value=U_BKnoise, proc=UpdateAgBeRings
	CheckBox check0 title="Vscan", fSize=12, pos={40, 275}, variable=:Red2DPackage:U_Vscan, proc=CheckProcVscan
	CheckBox check1 title="Hscan", fSize=12, pos={120, 275}, variable=:Red2DPackage:U_Hscan, proc=CheckProcHscan
	Button button0 title="Get Points on Rings",size={150,25},pos={40,305},proc=ButtonProcGetPtOnRings
	Button button1 title="Fit Rings",size={150,25},pos={40,345},proc=ButtonProcRingFit
	Button button2 title="Refresh",size={150,25},pos={40,385},proc=ButtonProcRefreshRingFit

End


Function ButtonProcRefreshRingFit(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
		
			Red2D_CreAgBhPanel(1)
			
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End


Function UpdateAgBeRings(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
			DrawAgBhRings(0.3)
			
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End


Function CheckProcVscan(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			
			NVAR Vscan = :Red2DPackage:U_Vscan
			Vscan = checked
			
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End


Function CheckProcHscan(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			
			NVAR Hscan = :Red2DPackage:U_Hscan
			Hscan = checked
			
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End


Function ButtonProcGetPtOnRings(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up

			GetPointsOnRings()

			break
		case -1: // control being killed
			break
	endswitch
	return 0
End


Function ButtonProcRingFit(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up

			FitAgBhRings()

			break
		case -1: // control being killed
			break
	endswitch
	return 0
End


/////////////////////////////////////////////////
//////////////     Actual Code     //////////////
/////////////////////////////////////////////////

/// Create AgBhRings based on tilt angle, plus initial guess for SDD, X0 and Y0.
/// @Param[in] AgBhImage
/// @Param[in] U_X0, U_Y0, U_SDD, U_startR, U_endR, U_tiltxyz, U_PixelSize, U_lambda
/// @Param[out] refAgBh, refAgBhID, refAgBhPhi: ROI showing rings
/// @Param[out] radiusX_corr, radiusY_corr, centerX_corr, centerX_corr: correction factors
Static Function DrawAgBhRings(margine)
	variable margine
	/// Check if in the Image folder
	If(Red2Dimagelistexist() != 0)
		Abort "You may in a wrong datafolder."
	Endif
	
	/// Get top image, which should be AgBh
	Dowindow/F $(WinName(0,1)) // Activate the top graph window
	String TopImageName = ImageNameList("", ";")
	TopImageName = StringFromList(0, TopImageName)
	TopImageName = ReplaceString("'", TopImageName, "") // delete 'name' from the name. Otherwise igor does not function.
	Wave TopImage = $TopImageName
	
	/// Get global variables I need, then create waves in Red2Dpackage
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
		Variable/G U_X0, U_Y0, U_SDD, U_PixelSize, U_tiltX, U_tiltY, U_tiltZ, U_startR, U_endR, U_Lambda
		variable Xrad = U_tiltX*pi/180
		variable Yrad = U_tiltY*pi/180
		variable Zrad = U_tiltZ*pi/180
		Duplicate/O TopImage, refAgBh, refAgBhID, refAgBhPhi
		Redimension/D refAgBhPhi // make phi double float. Need this for better sorting.
		Multithread refAgBh = 0; Multithread refAgBhID = 0; Multithread refAgBhPhi = 0
	
	/// Create q, theta of AgBe from reference. This process needs to be here because calculation of AgBh_ta.
	Make/O/N=13 AgBh_q, AgBh_ta, radiusX_corr, radiusY_corr, centerX_corr, centerY_corr
	AgBh_q[0,10] = 0.1076*(p+1) //a good approximation
	AgBh_q[11,12] = {1.369, 1.387} //doublet not in use. The fit works fine without the doublet.
	AgBh_ta = 2*asin(AgBh_q*U_Lambda/(4*pi))
	
	/// Calc correction factors
	variable tilt
	If(Xrad != 0 && Yrad != 0)
		SetdataFolder saveDFR
		Abort "This package does not support simulatenous tilts for multiaxis"
	Elseif(Xrad == 0 && Yrad == 0)
		radiusX_corr = tan(AgBh_ta) / (U_PixelSize*1e-6)
		radiusY_corr = radiusX_corr
		centerX_corr = 0
		centerY_corr = 0
	Elseif(Xrad != 0 && Yrad == 0)
		tilt = Xrad
		radiusY_corr = 0.5 * sin(AgBh_ta) * ( 1/cos(AgBh_ta-abs(tilt)) + 1/cos(AgBh_ta+abs(tilt)) ) / (U_PixelSize*1e-6)
		radiusX_corr = radiusY_corr * sqrt(1 - ( sin(tilt) / cos(AgBh_ta) )^2 )
		centerX_corr = 0
		centerY_corr = radiusY_corr*tan(AgBh_ta)*tan(tilt)
	Elseif(Xrad == 0 && Yrad != 0)
		tilt = Yrad
		radiusX_corr = 0.5 * sin(AgBh_ta) * ( 1/cos(AgBh_ta-abs(tilt)) + 1/cos(AgBh_ta+abs(tilt)) ) / (U_PixelSize*1e-6)
		radiusY_corr = radiusX_corr * sqrt(1 - ( sin(tilt) / cos(AgBh_ta) )^2 )
		centerY_corr = 0
		centerX_corr = -radiusX_corr*tan(AgBh_ta)*tan(tilt) // negative sign makes correction factor being consistent with Euler angle.
	Endif

	/// Draw Rings
	Duplicate/O AgBh_ta, radiusX, radiusY, centerX, centerY
	radiusX = U_SDD * radiusX_corr // these waves contain all 13 rings of AgBh
	radiusY = U_SDD * radiusY_corr
	centerX = U_X0 + U_SDD * centerX_corr
	centerY = U_Y0 + U_SDD * centerY_corr
	
	Duplicate/O/FREE TopImage, tempImage	
	variable i
	For(i=U_startR-1;i<U_endR;i++) // i = U_startR - 1 converts the number of U_startR to index
		/// check if p and q in range.
		MultiThread tempImage = (p-centerX[i])^2/radiusX[i]^2 + (q-centerY[i])^2/radiusY[i]^2 >= 1-margine/(i/2+1) && (p-centerX[i])^2/radiusX[i]^2 + (q-centerY[i])^2/radiusY[i]^2 <= 1+margine/(i/2+1)
		MatrixOP/O refAgBh = refAgBh+tempImage
		MatrixOP/O refAgBhID = refAgBhID+tempImage*i // ring id start from 0
		
		If(i == U_startR-1) // run first time
		MultiThread refAgBhPhi = imag( r2polar( cmplx(p-U_X0, q-U_Y0) ) )/pi*180
		Endif
	Endfor

	/// Update Rings overlap.	
	RemoveImage/Z refAgBh // ImageName is the actual Image Name, not the wave name
	AppendImage/T refAgBh // When appending it should be wave name
	ModifyImage refAgBh explicit=1, eval={1,0,0,0,0}, eval={0,60000,60000,60000, 60000} // eval is color. (eval={value, red, green, blue [, alpha]})
	
SetdataFolder saveDFR
	
End

/// @Param[in] AgBhImage
/// @Param[in] refAgBh, refAgBhID, refAgBhPhi : ROI showing rings
/// @Param[in] radiusX_corr, radiusY_corr, centerX_corr, centerY_corr : waves containing correction parameters of all rings
/// @Param[out] ringX_conc, ringY_conc : concatenated XY positions of points rings
/// @Param[out] radiusX_corr_conc, radiusY_corr_conc, centerX_corr_conc, centerY_corr_conc, ringID : concatenated correction parameters of rings
Static Function GetPointsOnRings()
	/// Check if in the Image folder
	If(Red2Dimagelistexist() != 0)
		Abort "Check if in the correct datafolder."
	Endif
	
	/// Get top image, which should be AgBh
	Dowindow/F $(WinName(0,1)) // Activate the top graph window
	String TopImageName = ImageNameList("", ";")
	TopImageName = StringFromList(0, TopImageName)
	TopImageName = ReplaceString("'", TopImageName, "") // delete 'name' from the name. Otherwise igor does not function.
	Wave TopImage = $TopImageName
	
	/// Get global variables I need, then create waves in Red2Dpackage
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage

	Variable/G U_startR, U_endR, U_Vscan, U_Hscan, U_BKnoise
	wave refAgBh, refAgBhID, refAgBhPhi
	wave radiusX_corr, radiusY_corr, centerX_corr, centerY_corr
	
	/// Preparation for scan peaks
	variable rowsize, colsize
	rowsize = DimSize(TopImage, 1)
	colsize = DimSize(TopImage, 0)
	Duplicate/O/FREE TopImage, rowscan, colscan, PeakImgae
	variable startP, endP
	variable threshold = U_BKnoise
	rowscan = 0
	colscan = 0
	PeakImgae = 0
	
	/// Scan peaks in each row
	If(U_Vscan == 1)
	Make/FREE/N=(rowsize) row
	startP = 5
	endP = rowsize-5
	variable i, j, k, PeakFound
	For(i=0;i<colsize;i++)	
		row = TopImage[i][p]
		startp = 0; PeakFound = 0
		Do
		FindPeak/Q/I/P/B=3/M=(threshold)/R=[startp, endP] row		
		
		IF(V_Flag != 0)
			break
		Endif

		rowscan[i][V_PeakLoc] = 1
		startp = V_TrailingEdgeLoc + 1
		PeakFound ++
		While(PeakFound < 50) // Prevent endless bug loop
	Endfor
	Else
	rowscan = 1
	Endif
	
	/// Scan peaks in each column
	If(U_Hscan == 1)
	Make/FREE/N=(colsize) col
	startP = 5
	endP = colsize-5
	For(i=0;i<rowsize;i++)
		col = TopImage[p][i]
		startp = 0; PeakFound = 0
		Do
		FindPeak/Q/I/P/B=3/M=(threshold)/R=[startp, endP] col
		
		IF(V_Flag != 0)
			break
		Endif	
		
		colscan[V_PeakLoc][i] = 1
		startp = V_TrailingEdgeLoc + 1
		PeakFound ++		
		While(PeakFound < 50) // Prevent endless bug loop
	Endfor
	Else
	colscan = 1
	Endif
	
	/// Remove uncertain peaks
	PeakImgae = rowscan * colscan
		
	/// Allocate points to each peaks
	Make/O/FREE/N=(1e5,13) ringX_all, ringY_all, ringPhi_all
	Make/O/FREE/N=13 count_all
	Multithread ringX_all = 0; 	Multithread ringY_all = 0; Multithread ringPhi_all = 0
	count_all = 0
	
	variable ringNum, count
	For(i=0;i<colsize;i++)
		For(j=0;j<rowsize;j++)
			
			If(refAgBh[i][j] == 1 && PeakImgae[i][j] == 1) // If target pixel in refAgBh and target pixel on peakImage
				ringNum = refAgBhID[i][j] // get ID of the ring e.g. 0, 1, 2 ...
				count = count_all[ringNum] // point number of the ring
				ringX_all[count][ringNum] = i // store the X position
				ringY_all[count][ringNum] = j // store the Y position
				ringPhi_all[count][ringNum] = refAgBhPhi[i][j] // store the phi
				count_all[ringNum] += 1
			Endif
			
		Endfor
	Endfor
	
	/// Extract necessary rings then redimension, sort, create Corr waves and Concatenate them
	Make/O/N=0 ringX_conc, ringY_conc, radiusX_corr_conc, radiusY_corr_conc, centerX_corr_conc, centerY_corr_conc, ringID_conc // make conc waves
	For(i=U_startR-1;i<U_endR;i++)
		/// Extract rings
		Make/O/FREE/N=1e5 temp_ringX, temp_ringY, temp_ringPhi
		Multithread temp_ringX = 0; Multithread temp_ringY = 0; Multithread temp_ringPhi = 0
		
		temp_ringX = ringX_all[p][i]
		temp_ringY = ringY_all[p][i]
		temp_ringPhi = ringPhi_all[p][i]
		
		/// Redimension
		count = count_all[i]
		Redimension/N=(count) temp_ringX, temp_ringY, temp_ringPhi //cut unecessary points
		
		/// Sort
		Sort temp_ringPhi, temp_ringX, temp_ringY // this is not necessary but makes the graph looks better. The fit works fine without the sort.
		
		/// Create correction waves
		Duplicate/O/FREE temp_ringX, temp_radiusX_corr, temp_radiusY_corr, temp_centerX_corr, temp_centerY_corr, temp_ringID
		temp_radiusX_corr = radiusX_corr[i] //apply correction parameters
		temp_radiusY_corr = radiusY_corr[i]
		temp_centerX_corr = centerX_corr[i]
		temp_centerY_corr = centerY_corr[i]
		temp_ringID = i //apply id of each rings for controling the color of plots
		
		/// Concatenate waves
		Concatenate/NP {temp_ringX}, ringX_conc // concatenated X of points on rings
		Concatenate/NP {temp_ringY}, ringY_conc // concatenated Y of points on rings
		Concatenate/NP {temp_radiusX_corr}, radiusX_corr_conc
		Concatenate/NP {temp_radiusY_corr}, radiusY_corr_conc
		Concatenate/NP {temp_centerX_corr}, centerX_corr_conc
		Concatenate/NP {temp_centerY_corr}, centerY_corr_conc	
		Concatenate/NP {temp_ringID}, ringID_conc
	Endfor
	
	/// Append obtained points on image
	variable refringnum = WaveMax(ringID_conc)	
	RemoveFromGraph/Z ringY_conc
	AppendToGraph/T ringY_conc vs ringX_conc
	
	If(refringnum == 0)
		ModifyGraph mode=3,marker=8,mrkThick=0.75, zColor(ringY_conc)={:ringID_conc,1,1,CyanMagenta,0}
	Else
		ModifyGraph mode=3,marker=8,mrkThick=0.75, zColor(ringY_conc)={:ringID_conc,*,*,CyanMagenta,0}
	Endif
	SetdataFolder saveDFR

End


/// Fitting function
Function FitAgBhEllipse(w, ringX_conc, ringY_conc, radiusX_corr_conc, radiusY_corr_conc, centerX_corr_conc, centerY_corr_conc) : FitFunc
	Wave w
	Variable ringX_conc
	Variable ringY_conc
	Variable radiusX_corr_conc
	Variable radiusY_corr_conc
	Variable centerX_corr_conc
	Variable centerY_corr_conc
	
	//CurveFitDialog/
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = SDD
	//CurveFitDialog/ w[1] = X0
	//CurveFitDialog/ w[2] = Y0
	
	variable radiusX_conc, radiusY_conc, centerX_conc, centerY_conc
	radiusX_conc = w[0] * radiusX_corr_conc
	radiusY_conc = w[0] * radiusY_corr_conc
	centerX_conc = w[1] + w[0] * centerX_corr_conc
	centerY_conc = w[2] + w[0] * centerY_corr_conc
	
	return sqrt(  ( (ringX_conc - centerX_conc)/radiusX_conc )^2  +  ( (ringY_conc - centerY_conc)/radiusY_conc )^2  ) - 1
End


/// Do fit for the concatenated points
/// @Param[in] FitAgBhEllipse : fit function
/// @Param[in] ringX_conc, ringY_conc, radiusX_corr_conc, radiusY_corr_conc, centerX_corr_conc, centerY_corr_conc, ringID_conc: concatenated parameters
/// @Param[out] U_SDD, U_X0, U_Y0 : fitting parameters
Function FitAgBhRings()
	/// Check if in the Image folder
	If(Red2Dimagelistexist() != 0)
		Abort "Check if in the correct datafolder."
	Endif
	
	/// Get top image, which should be AgBh
	Dowindow/F $(WinName(0,1)) // Activate the top graph window
	String TopImageName = ImageNameList("", ";")
	TopImageName = StringFromList(0, TopImageName)
	TopImageName = ReplaceString("'", TopImageName, "") // delete 'name' from the name. Otherwise igor does not function.
	Wave TopImage = $TopImageName
	
	/// Get global variables I need, then create waves in Red2Dpackage
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
	Variable/G U_X0, U_Y0, U_SDD
	Wave ringID_conc, ringX_conc, ringY_conc, radiusX_corr_conc, radiusY_corr_conc, centerX_corr_conc, centerY_corr_conc
	
	/// Do fit
	Duplicate/O ringID_conc, Dummy, FitErrors
	Dummy = 0; FitErrors = 0

	Make/D/N=3/O W_coef // SDD, X0, Y0
	W_coef[0] = U_SDD
	W_coef[1] = U_X0
	W_coef[2] = U_Y0

	FuncFit/TBOX=776 FitAgBhEllipse W_coef Dummy /X={ringX_conc, ringY_conc, radiusX_corr_conc, radiusY_corr_conc, centerX_corr_conc, centerY_corr_conc} /D=FitErrors
	
	/// Store fitted results
	U_SDD = W_coef[0]
	U_X0 = W_coef[1]
	U_Y0 = W_coef[2]

	SetDataFolder saveDFR
	
	DrawAgBhRings(0.3)
End





