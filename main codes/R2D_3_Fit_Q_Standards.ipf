#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// Goal of this procedure:
/// Fit standard sample of q and get SDD and X0, Y0.

/////////////////////////////////////////////////
//////////////         GUI         //////////////
/////////////////////////////////////////////////

Function R2D_CreStdFitPanel()
	
	/// Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and imagelist.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif

	//////////Set Global variables//////////
	String reflist = wavelist("*",";","DIMS:2,TEXT:0") //Get wavelist from current folder limited for 2D waves
	Wave/T reftw = ListToTextWave(reflist,";") // Create a text wave reference containing reflist
	Wave TopImage = $reftw[0]

	DFREF saveDFR = GetDataFolderDFR()
	NewDataFolder/O/S Red2DPackage  // create Red2D package datafolder and set current datafolder to the package folder.
		Variable/G U_Xmax, U_Ymax, U_X0, U_Y0, U_SDD, U_Lambda, U_PixelSize, U_tiltX, U_tiltY, U_tiltZ, U_startR, U_endR, U_Vscan, U_Hscan, U_BKnoise, U_margin, U_current_STD
		String/G U_MaskName_FitStd
		U_Xmax=Dimsize(TopImage,0)-1 //Get image size. Minus 1 because Dimsize is size while Xmax means the coordinates.
		U_Ymax=Dimsize(TopImage,1)-1 //Get image size

		/// Initialize
		
		If(numtype(U_current_STD) != 0 || U_current_STD == 0)
			U_current_STD = 1
		Endif
		If(numtype(U_X0) != 0)
			U_X0 = 0
		Endif
		If(numtype(U_Y0) != 0)
			U_Y0 = 0
		Endif
		If(U_SDD == 0 || numtype(U_SDD) != 0)
			U_SDD = 1
		Endif
		If(U_Lambda == 0 || numtype(U_Lambda) != 0)
			U_Lambda = 1
		Endif
		If(U_PixelSize == 0 || numtype(U_PixelSize) != 0)
			U_PixelSize = 172
		Endif
		If(numtype(U_tiltX) != 0)
			U_tiltX = 0
		Endif
		If(numtype(U_tiltY) != 0)
			U_tiltY = 0
		Endif
		If(numtype(U_tiltZ) != 0)
			U_tiltZ = 0
		Endif		
		If(U_startR == 0 || numtype(U_startR) != 0)
			U_startR = 1
		Endif
		If(U_endR == 0 || numtype(U_endR) != 0)
			U_endR = 1
		Endif
		If(U_margin == 0 || numtype(U_margin) != 0)
			U_margin = 0.3
		Endif
		
		U_Vscan = 1
		U_Hscan = 1
		If(numtype(U_BKnoise) != 0)
			U_BKnoise = 0
		Endif
	
	SetdataFolder saveDFR
	
	/// Check if panel exist
	DoWindow Fit_Q_Standards
	If(V_flag == 0)
		NewPanel/K=1/N=Fit_Q_Standards/W=(400, 300, 630, 850)
	Else
		DoWindow/F Fit_Q_Standards
	Endif
	
	
	//////////Create a panel with buttons//////////
	PopupMenu popup0 title="Standard", pos={15,10}, fSize=13, value="AgBh;Si;CeO2;Chicken Tendon", mode=U_current_STD, proc=Update_current_STD
	Execute/P/Q "PopupMenu popup0 pos={15,10}"  // a workaround about Igor's know bug for bodywidth option.
	SetVariable setvar0 title="X0 [pt]",pos={15,35},size={200,25},limits={-inf,inf,10},fSize=13, value=U_X0, proc=UpdateStdRings
	SetVariable setvar1 title="Y0 [pt]",pos={15,60},size={200,25},limits={-inf,inf,10},fSize=13, value=U_Y0, proc=UpdateStdRings
	SetVariable setvar2 title="SDD [m]",pos={15,85},size={200,25},limits={0,inf,0.01},fSize=13, value=U_SDD, proc=UpdateStdRings
	SetVariable setvar3 title="Tilt_X [º]",pos={15,110},size={200,25},limits={-90,90,1},fSize=13, value=U_tiltX, help={"-90 to 90º"}, proc=UpdateStdRings
	SetVariable setvar4 title="Tilt_Y [º]",pos={15,135},size={200,25},limits={-90,90,1},fSize=13, value=U_tiltY, help={"-90 to 90º"}, proc=UpdateStdRings
	SetVariable setvar5 title="Lambda [A]",pos={15,160},size={200,25},limits={0,inf,0.1},fSize=13, value=U_Lambda, help={"Cu = 1.5418A, Mo = 0.7107A"}, proc=UpdateStdRings
	SetVariable setvar6 title="Pixel size [um]",pos={15,185},size={200,25},limits={0,inf,1},fSize=13, value=U_PixelSize, help={"Pilatus = 172um, Rigaku = 100um, Eiger = 75um"}, proc=UpdateStdRings
	SetVariable setvar7 title="First ring to fit",pos={15,210},size={200,25},limits={1,11,1},fSize=13, value=U_startR, proc=UpdateStdRings
	SetVariable setvar8 title="Last ring to fit",pos={15,235},size={200,25},limits={1,11,1},fSize=13, value=U_endR, proc=UpdateStdRings
	SetVariable setvar9 title="Ring width",pos={15,260},size={200,25},limits={0.001,1,0.1},fSize=13, value=U_margin, proc=UpdateStdRings
	SetVariable setvar10 title="Background int",pos={15,285},size={200,25},limits={0,inf,100},fSize=13, value=U_BKnoise, proc=UpdateStdRings
	CheckBox check0 title="Vscan", fSize=12, pos={50, 345}, variable=:Red2DPackage:U_Vscan, proc=CheckProcVscan
	CheckBox check1 title="Hscan", fSize=12, pos={130, 345}, variable=:Red2DPackage:U_Hscan, proc=CheckProcHscan
	Button button0 title="Get Points on Rings",size={150,23},pos={40,380},proc=ButtonProcGetPtOnRings
	Button button1 title="Fit Rings",size={150,23},pos={40,420},proc=ButtonProcRingFit
	Button button2 title="Refresh",size={150,23},pos={40,460},proc=ButtonProcRefreshRingFit
	Button button3 title="Quick Beam Center",size={150,23},pos={40,500},proc=ButtonProcQuickBeamCenter
	
	PopupMenu popup1 title="Mask", pos={15,310}, fSize=13, bodyWidth=165, value=R2D_GetMaskList_simple(), proc=Update_Mask_FitStd
	// R2D_GetMaskList_simple is located in the Circular Average Proc.
	// when refresh above popup, the selection number will remain in old one. Therefore, when it exceeds current list, no selection appears.
	Execute/P/Q "PopupMenu popup1 pos={15,310}"  // a workaround about Igor's know bug for bodywidth option.
	
	// !!! make sure to check if the control name is refered at somewhere before change their names.
	
End

Function Update_current_STD(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			NVAR current_STD = :Red2DPackage:U_current_STD
			current_STD = popNum // remeber current selection
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



Function ButtonProcRefreshRingFit(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up

			R2D_CreStdFitPanel()
			
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End


Function UpdateStdRings(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
		
			NVAR margin = :Red2DPackage:U_margin
			DrawStdRings(margin)
			
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

			FitStdRings()

			break
		case -1: // control being killed
			break
	endswitch
	return 0
End


Function ButtonProcQuickBeamCenter(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up

			R2D_GetBeamCenter_SelectedImage()
			
			NVAR margin = :Red2DPackage:U_margin
			DrawStdRings(margin)

			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function Update_Mask_FitStd(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa


	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			String ImageFolderPath = R2D_GetImageFolderPath()	// Get image datafolder even 1D folder is activated.
			If(strlen(ImageFolderPath) == 0)
				Abort "You may be in a wrong datafolder."
			Endif
			DFREF saveDFR = GetDataFolderDFR()	// get current datafolder. It could be image folder or 1D folder.
			SetDataFolder $ImageFolderPath		// move to image folder
			
			String/G :Red2DPackage:U_MaskName_FitStd
			SVAR MaskName_FitStd = :Red2DPackage:U_MaskName_FitStd
			MaskName_FitStd = popStr // remeber current selection
			
			// remove old mask. the ring image should not be removed.
			String oldimage_List = ImageNameList("IntensityImage",";") // Get existing ImageName in the window ImageGraph
			variable oldimage_num = itemsInList(oldimage_List)
			string oldimage_name
			variable i
			for(i=oldimage_num-1; i>0; i--)	// remove images after appending new one to prevent weird behavior of igor pro image graph.
				oldimage_name = StringFromList(i,oldimage_List)	// remove from oldest images
				if(stringmatch(oldimage_name, "refStd") || stringmatch(oldimage_name, "PeakImgae"))
					// do nothing
				else
					RemoveImage/Z/W=IntensityImage $oldimage_name
				endif
			endfor
			
			if(!stringmatch("no mask", MaskName_FitStd))	// if any mask is selected.
				wave mask_wave = $(":Red2DPackage:Mask:"+MaskName_FitStd)
				R2D_AppendMaskToImage(mask_wave)
			endif

			SetDataFolder saveDFR
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


/////////////////////////////////////////////////
//////////////     Actual Code     //////////////
/////////////////////////////////////////////////

/// Stored peak posiitons of the standard samples.
Static Function/WAVE Create_AgBh_ref()
	Make/FREE/O/N=11 AgBh_q
	AgBh_q[0,10] = 0.1076*(p+1) //a good approximation
	// Huang, T. C., Toraya, H., Blanton, T. N. & Wu, Y. X-ray powder diffraction analysis of silver behenate, a possible low-angle diffraction standard. Journal of Applied Crystallography 26, 180–184 (1993).
  
	return AgBh_q
End

Static Function/WAVE Create_Si_ref()
	Make/FREE/O/N=11 Si_q
	Si_q[0,10] = {2.004, 3.272, 3.837, 4.628, 5.043, 5.668, 6.012, 6.545, 6.845, 7.317, 7.587}
	// Silicon_640f_Standard_certification_NIST.pdf
	return Si_q
End

Static Function/WAVE Create_CeO2_ref()
	Make/FREE/O/N=6 CeO2_q
	CeO2_q[0,5] = {2.015464356, 2.326270904, 3.287816681, 3.853976194, 4.025376915, 4.647132202}
	// NIST_SRM_676b_%5BZnO,TiO2,Cr2O3,CeO2%5D.pdf 

	return CeO2_q
End

Static Function/WAVE Create_Tendon_ref()
	Make/FREE/O/N=6 Tendon_q
	Tendon_q[0,5] = {0.00946, 0.01892, 0.02838, 0.03784, 0.0473, 0.05676}
	return Tendon_q
End


/// Create StdRings based on tilt angle, plus initial guess for SDD, X0 and Y0.
/// @Param[in] StdImage
/// @Param[in] U_X0, U_Y0, U_SDD, U_startR, U_endR, U_tiltxyz, U_PixelSize, U_lambda
/// @Param[out] refStd, refStdID, refStdPhi: ROI showing rings
/// @Param[out] radiusX_corr, radiusY_corr, centerX_corr, centerX_corr: correction factors
Static Function DrawStdRings(margine)
	variable margine
	/// Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and imagelist.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	/// Get top image, which should be Std
//	Dowindow/F $(WinName(0,1)) // Activate the top graph window
	String TopImageName = ImageNameList("IntensityImage", ";")
	TopImageName = StringFromList(0, TopImageName)
	TopImageName = ReplaceString("'", TopImageName, "") // delete 'name' from the name. Otherwise igor does not function.
	if(strlen(TopImageName) == 0)
		Print "IntensityImage window does not exist."
		return -1
	endif
	Wave TopImage = $TopImageName
	
	/// Get global variables I need, then create waves in Red2Dpackage
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
		Variable/G U_X0, U_Y0, U_SDD, U_PixelSize, U_tiltX, U_tiltY, U_tiltZ, U_startR, U_endR, U_Lambda
		variable Xrad = U_tiltX*pi/180
		variable Yrad = U_tiltY*pi/180
		variable Zrad = U_tiltZ*pi/180
		Duplicate/O TopImage, refStd, refStdID, refStdPhi
		Redimension/D refStdPhi // make phi double float. Need this for better sorting.
		Multithread refStd = 0; Multithread refStdID = 0; Multithread refStdPhi = 0
	
	ControlInfo/W=Fit_Q_Standards popup0
	Strswitch(S_Value)	// s_value is the result from controlinfo. s_value stores a string of the selected popup menu item.
		Case "AgBh":
			wave Std_q = Create_AgBh_ref()
			break
		Case "Si":
			wave Std_q = Create_Si_ref()
			break
		Case "CeO2":
			wave Std_q = Create_CeO2_ref()
			break
		Case "Chicken Tendon":
			wave Std_q = Create_Tendon_ref()
			break
		Default:
			SetdataFolder saveDFR
			print "The reference peak values of the selected item cannot be found."
			Abort "The reference peak values of the selected item cannot be found."
		break
		
	Endswitch
	Duplicate/O Std_q, Std_ta, radiusX_corr, radiusY_corr, centerX_corr, centerY_corr
	Std_ta = 2*asin(Std_q*U_Lambda/(4*pi)) // theta of Std in Angstrom
	
	/// Calculate correction factors from the stored reference peaks of standard samples, e.g. AbBh, Si, CeO2.
	/// The correctoin factors simplify the latter calculation.
	/// You can get the radius or center of any reference peak on the detector by multiplying SDD or the apparent beam center.
	variable tilt
	If(Xrad != 0 && Yrad != 0)
		SetdataFolder saveDFR
		Abort "This package does not support simulatenous tilts for multi-axis."
	Elseif(Xrad == 0 && Yrad == 0)
		radiusX_corr = tan(Std_ta) / (U_PixelSize*1e-6) // radius_corrs will be used to calculate the radius of referennce peaks on the detector.
		radiusY_corr = radiusX_corr
		centerX_corr = 0
		centerY_corr = 0
	Elseif(Xrad != 0 && Yrad == 0)
		tilt = Xrad
		radiusY_corr = 0.5 * sin(Std_ta) * ( 1/cos(Std_ta-abs(tilt)) + 1/cos(Std_ta+abs(tilt)) ) / (U_PixelSize*1e-6)
		radiusX_corr = radiusY_corr * sqrt(1 - ( sin(tilt) / cos(Std_ta) )^2 )
		centerX_corr = 0
		centerY_corr = radiusY_corr*tan(Std_ta)*tan(tilt)
	Elseif(Xrad == 0 && Yrad != 0)
		tilt = Yrad
		radiusX_corr = 0.5 * sin(Std_ta) * ( 1/cos(Std_ta-abs(tilt)) + 1/cos(Std_ta+abs(tilt)) ) / (U_PixelSize*1e-6)
		radiusY_corr = radiusX_corr * sqrt(1 - ( sin(tilt) / cos(Std_ta) )^2 )
		centerY_corr = 0
		centerX_corr = -radiusX_corr*tan(Std_ta)*tan(tilt) // negative sign makes correction factor being consistent with Euler angle.
	Endif

	/// Draw Rings
	Duplicate/O Std_ta, radiusX, radiusY, centerX, centerY
	radiusX = U_SDD * radiusX_corr // these waves contain the radius of all reference peaks of the standard sample.
	radiusY = U_SDD * radiusY_corr
	centerX = U_X0 + U_SDD * centerX_corr
	centerY = U_Y0 + U_SDD * centerY_corr
	
	Duplicate/O/FREE TopImage, tempImage	
	variable i
	For(i=U_startR-1;i<U_endR;i++) // U_startR is the selected initial number of Std rings, U_endR is the selected last number of Std rings
	
		// This for loop creates a ring with the corresponding condition and add it to the tempImage.
		// The ROI is 1 and the masked region is 0. 1 is transparent and 0 is semitrasparent.
		// refStd is uesd to store the all ROI of rings, where 1 is stored at pixels of ROI.
		/// check if p and q in range.
		MultiThread tempImage = (p-centerX[i])^2/radiusX[i]^2 + (q-centerY[i])^2/radiusY[i]^2 >= 1-margine/(i/2+1) && (p-centerX[i])^2/radiusX[i]^2 + (q-centerY[i])^2/radiusY[i]^2 <= 1+margine/(i/2+1)
		MatrixOP/O refStd = refStd+tempImage
		MatrixOP/O refStdID = refStdID+tempImage*(i+1) // background is 0, and ring ID starts from 1.
		
		If(i == U_startR-1) // run first time
			MultiThread refStdPhi = imag( r2polar( cmplx(p-U_X0, q-U_Y0) ) )/pi*180
		Endif
		
	Endfor

	/// Update Rings overlap.	
	PauseUpdate
	RemoveImage/Z/W=IntensityImage refStd // ImageName is the actual Image Name, not the wave name
	AppendImage/T/W=IntensityImage refStd // When appending it should be wave name
	ModifyImage/W=IntensityImage refStd explicit=1, eval={1,0,0,0,0}, eval={0,60000,60000,60000, 60000} // eval is color. (eval={value, red, green, blue [, alpha]})
	ResumeUpdate
SetdataFolder saveDFR
	
End

/// @Param[in] StdImage
/// @Param[in] refStd, refStdID, refStdPhi : ROI showing rings
/// @Param[in] radiusX_corr, radiusY_corr, centerX_corr, centerY_corr : waves containing correction parameters of all rings
/// @Param[out] ringX_conc, ringY_conc : concatenated XY positions of points rings
/// @Param[out] radiusX_corr_conc, radiusY_corr_conc, centerX_corr_conc, centerY_corr_conc, ringID : concatenated correction parameters of rings
/// waves with "corr" are correction waves. The correction factors are calculated from the stored reference values of std sample.
Static Function GetPointsOnRings()
	/// Check if in the image folder.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	/// Get top image, which should be Std
//	Dowindow/F $(WinName(0,1)) // Activate the top graph window
	String TopImageName = ImageNameList("IntensityImage", ";")
	TopImageName = StringFromList(0, TopImageName)
	TopImageName = ReplaceString("'", TopImageName, "") // delete 'name' from the name. Otherwise igor does not function.
	Wave TopImage = $TopImageName
	
	// Get mask wave
	String/G :Red2DPackage:U_MaskName_FitStd
	SVAR MaskName_FitStd = :Red2DPackage:U_MaskName_FitStd
	wave/Z mask_wave = $(":Red2DPackage:Mask:"+ MaskName_FitStd)
	if(!WaveExists(mask_wave))
		Duplicate/O/FREE $TopImageName, mask_wave
		MultiThread mask_wave = 0	// if mask wave does not exist, make a dummy mask wave. This simplify the latter codes.
	endif
	
	/// Get global variables I need, then create waves in Red2Dpackage
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage

	Variable/G U_startR, U_endR, U_Vscan, U_Hscan, U_BKnoise
	wave refStd, refStdID, refStdPhi
	wave radiusX_corr, radiusY_corr, centerX_corr, centerY_corr
	
	/// Preparation for scan peaks
	variable rowsize, colsize
	rowsize = DimSize(TopImage, 1)
	colsize = DimSize(TopImage, 0)
	Duplicate/O/FREE TopImage, refTopImage, rowscan, colscan, PeakImgae  // rowscan and colscan stores the peak positions by each scan. Peakimage is a common items of two image.
	Multithread refTopImage[][] = numtype(TopImage[p][q]) == 2 ? -1 : TopImage[p][q] // findpeak cannot properly deal with NaN. Therefore, I changed the NaN in the image to -1 only for this process.
	variable startP, endP
	variable threshold = U_BKnoise
	Multithread rowscan = 0
	Multithread colscan = 0
	Multithread PeakImgae = 0
	
	/// Scan peaks in each row
	If(U_Vscan == 1)
	Make/FREE/N=(rowsize) row
	startP = 5  // do not use the first and last a few points to avoid the noise at the edges.
	endP = rowsize-5
	variable i, j, k, PeakFound
	For(i=0;i<colsize;i++)	
		row = refTopImage[i][p]
		startp = 0; PeakFound = 0
		Do
		FindPeak/Q/I/P/B=3/M=(threshold)/R=[startp, endP] row		
		
		IF(V_Flag != 0)
			break
		Endif

		rowscan[i][V_PeakLoc] = 1
		startp = V_TrailingEdgeLoc + 1
		PeakFound ++
		While(PeakFound < 50) // Prevent endless bug loop. maximum 50 for each row in the image.
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
		col = refTopImage[p][i]
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
	Make/O/FREE/N=(1e5,13) ringX_all, ringY_all, ringPhi_all  // store the 
	Make/O/FREE/N=13 count_all  // store the number of points found on each ring at each data point.
	Multithread ringX_all = 0; 	Multithread ringY_all = 0; Multithread ringPhi_all = 0
	count_all = 0
	
	variable ringID, count
	For(i=0;i<colsize;i++)
		For(j=0;j<rowsize;j++)
			
			If(refStd[i][j] == 1 && PeakImgae[i][j] == 1 && mask_wave[i][j] == 0) // If target pixel in refStd and target pixel on peakImage and the pixel is not masked (i.e. mask_Wave = 0)
				ringID = refStdID[i][j] -1 // get ID of the ring e.g. 0, 1, 2 ... 2020-08-06 refStdID[i][j] --> refStdID[i][j] - 1, ring id now starts from 1.
				count = count_all[ringID] // the count_th points on the ring
				ringX_all[count][ringID] = i // store the X position
				ringY_all[count][ringID] = j // store the Y position
				ringPhi_all[count][ringID] = refStdPhi[i][j] // store the phi
				count_all[ringID] += 1
			Endif
			
		Endfor
	Endfor
	
	
	/// Extract necessary rings then redimension, sort, create Correctionn waves and Concatenate them
	Make/O/N=0 ringX_conc, ringY_conc, radiusX_corr_conc, radiusY_corr_conc, centerX_corr_conc, centerY_corr_conc, ringID_conc // make conc waves
	For(i=U_startR-1;i<U_endR;i++)
		/// Extract rings
		Make/O/FREE/N=1e5 temp_ringX, temp_ringY, temp_ringPhi
		Multithread temp_ringX = 0; Multithread temp_ringY = 0; Multithread temp_ringPhi = 0
		
		temp_ringX = ringX_all[p][i]
		temp_ringY = ringY_all[p][i]
		temp_ringPhi = ringPhi_all[p][i] // use to sort point along the ring
		
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
	variable dring = WaveMax(ringID_conc) - WaveMin(ringID_conc)
	RemoveFromGraph/Z ringY_conc
	AppendToGraph/T ringY_conc vs ringX_conc
	
	If(dring == 0)
		ModifyGraph mode=3,marker=8,mrkThick=0.75, zColor(ringY_conc)={:ringID_conc,U_startR-1,U_endR,CyanMagenta,0}
	Else
		ModifyGraph mode=3,marker=8,mrkThick=0.75, zColor(ringY_conc)={:ringID_conc,*,*,CyanMagenta,0}
	Endif
	
	SetdataFolder saveDFR

End


/// Fitting function
Function FitStdEllipse(w, ringX_conc, ringY_conc, radiusX_corr_conc, radiusY_corr_conc, centerX_corr_conc, centerY_corr_conc) : FitFunc
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
	
	// an general equation of ellipse. raidusX is the radius in X axis. ringX - centerX gives the x position of a point on the ring.
	return sqrt(  ( (ringX_conc - centerX_conc)/radiusX_conc )^2  +  ( (ringY_conc - centerY_conc)/radiusY_conc )^2  ) - 1
End


/// Do fit for the concatenated points
/// @Param[in] FitStdEllipse : fit function
/// @Param[in] ringX_conc, ringY_conc, radiusX_corr_conc, radiusY_corr_conc, centerX_corr_conc, centerY_corr_conc, ringID_conc: concatenated parameters
/// @Param[out] U_SDD, U_X0, U_Y0 : fitting parameters
Function FitStdRings()
	/// Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and imagelist.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	/// Get top image, which should be Std
//	Dowindow/F $(WinName(0,1)) // Activate the top graph window
	String TopImageName = ImageNameList("IntensityImage", ";")
	TopImageName = StringFromList(0, TopImageName)
	TopImageName = ReplaceString("'", TopImageName, "") // delete 'name' from the name. Otherwise igor does not function.
	Wave TopImage = $TopImageName
	
	/// Get global variables I need, then create waves in Red2Dpackage
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
	Variable/G U_X0, U_Y0, U_SDD
	Wave ringID_conc, ringX_conc, ringY_conc, radiusX_corr_conc, radiusY_corr_conc, centerX_corr_conc, centerY_corr_conc
	
	// check if ringID_conc exists,
	If(!WaveExists(ringID_conc))
		SetDataFolder saveDFR
		Abort "No Points to fit."	
	Endif
	
	/// Do fit
	Duplicate/O ringID_conc, Dummy, FitErrors
	Dummy = 0; FitErrors = 0

	Make/D/N=3/O W_coef // SDD, X0, Y0
	W_coef[0] = U_SDD
	W_coef[1] = U_X0
	W_coef[2] = U_Y0

	FuncFit/TBOX=776 FitStdEllipse W_coef Dummy /X={ringX_conc, ringY_conc, radiusX_corr_conc, radiusY_corr_conc, centerX_corr_conc, centerY_corr_conc} /D=FitErrors
	
	/// Store fitted results
	U_SDD = W_coef[0]
	U_X0 = W_coef[1]
	U_Y0 = W_coef[2]

	SetDataFolder saveDFR
	
	NVAR margin = :Red2DPackage:U_margin
	DrawStdRings(margin)
	
	DoWindow/H
End


Function R2D_GetBeamCenter_SelectedImage()

	String TopImageName = ImageNameList("IntensityImage", ";")
	TopImageName = StringFromList(0, TopImageName)
	TopImageName = ReplaceString("'", TopImageName, "") // delete 'name' from the name. Otherwise igor does not function.
	Wave TopImage = $TopImageName
	ImageStats TopImage
	
	NVAR X0 = :Red2DPackage:U_X0
	NVAR Y0 = :Red2DPackage:U_Y0
	
	X0 = V_maxRowLoc
	Y0 = V_maxColLoc
	
End





