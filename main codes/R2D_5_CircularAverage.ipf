#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

////////////////////////////////////////////////////////
////////////////////////GUI/////////////////////////////
////////////////////////////////////////////////////////

Function R2D_CircularAveragePanel()
	
	String ImageFolderPath = R2D_GetImageFolderPath()	// Get image datafolder even 1D folder is activated.
//			print ImageFolderPath
	If(strlen(ImageFolderPath) == 0)
		Abort "You may be in a wrong datafolder."
	Else
		String savedDF = GetDataFolder(1)	// save current folder as a reference
//		print savedDF
		SetDataFolder $ImageFolderPath	// set datafolder to the image folder
		String simple_imagefolderpath = GetDataFolder(1)		// for display, the default image folder path may contain ::
		NewDataFolder/O Red2Dpackage	// create an Red2Dpackage folder within the image folder
	Endif
	
	String reflist = wavelist("*",";","DIMS:2,TEXT:0") //Get wavelist from current folder limited for 2D waves
	Wave/T reftw = ListToTextWave(reflist,";") // Create a text wave reference containing reflist
	Wave TopImage = $reftw[0]
	
	
	// check if NVAR and SVAR exist, use this section to set default value
	// if you want to set the default value to zero, you do not need to specify it here.
	NVAR/Z U_sac = :Red2Dpackage:U_sac
	If(!NVAR_Exists(U_sac))
		Variable/G :Red2Dpackage:U_sac
		NVAR/Z U_sac = :Red2Dpackage:U_sac
		U_sac = 1
	Endif
	
	Variable/G :Red2Dpackage:U_Xmax, :Red2Dpackage:U_Ymax, :Red2Dpackage:U_X0, :Red2Dpackage:U_Y0
	Variable/G :Red2Dpackage:U_SDD, :Red2Dpackage:U_Lambda, :Red2Dpackage:U_PixelSize
	Variable/G :Red2Dpackage:U_tiltX, :Red2Dpackage:U_tiltY, :Red2Dpackage:U_tiltZ, :Red2Dpackage:U_SortOrder// U_tiltZ is not in use. It is actuall X2. I use X-Y-X type rotation.
	String/G :Red2Dpackage:U_MaskName_All_CA, :Red2Dpackage:U_MaskName_Auto
	Variable/G :Red2Dpackage:U_row_CA
	Variable/G :Red2Dpackage:U_sac
	
	NVAR U_Xmax = :Red2Dpackage:U_Xmax
	NVAR U_Ymax= :Red2Dpackage:U_Ymax
	NVAR U_X0 = :Red2Dpackage:U_X0
	NVAR U_Y0 = :Red2Dpackage:U_Y0
	NVAR U_SDD = :Red2Dpackage:U_SDD
	NVAR U_Lambda = :Red2Dpackage:U_Lambda
	NVAR U_PixelSize = :Red2Dpackage:U_PixelSize
	NVAR U_tiltX = :Red2Dpackage:U_tiltX
	NVAR U_tiltY = :Red2Dpackage:U_tiltY
	NVAR U_tiltZ = :Red2Dpackage:U_tiltZ
	NVAR U_SortOrder = :Red2Dpackage:U_SortOrder
	SVAR U_MaskName_All_CA = :Red2Dpackage:U_MaskName_All_CA
	SVAR U_MaskName_Auto = :Red2Dpackage:U_MaskName_Auto
	NVAR U_row_CA = :Red2Dpackage:U_row_CA
	NVAR U_sac = :Red2Dpackage:U_sac
		
	U_Xmax=Dimsize(TopImage,0)-1 //Get image size. Minus 1 because Dimsize is size while Xmax means the coordinates.
	U_Ymax=Dimsize(TopImage,1)-1 //Get image size
	
//	If(numtype(U_X0) != 0)
//		U_X0 = 0
//	Endif
//	If(numtype(U_X0) != 0)
//		U_Y0 = 0
//	Endif
	If(U_SDD == 0 || numtype(U_SDD) != 0)
		U_SDD = 1
	Endif
	If(U_Lambda == 0 || numtype(U_Lambda) != 0)
		U_Lambda = 1
	Endif
	If(U_PixelSize == 0 || numtype(U_PixelSize) != 0)
		U_PixelSize = 1
	Endif
//	If(numtype(U_tiltX) != 0)
//		U_tiltX = 0
//	Endif
//	If(numtype(U_tiltY) != 0)
//		U_tiltY = 0
//	Endif
//	If(numtype(U_tiltZ) != 0)
//		U_tiltZ = 0
//	Endif
	If(U_SortOrder == 0 || numtype(U_SortOrder) != 0)
		U_SortOrder = 1
	Endif
//	If(numtype(U_row_CA) != 0)
//		U_row_CA = 0
//	Endif

	/// Check if panel exist
	DoWindow CircularAverage
	If(V_flag == 0)
		NewPanel/K=1/N=CircularAverage/W=(200,200,900,550)
		SetWindow CircularAverage, hook(CircularAverageHook) = R2D_CircularAverageWindowHook	
	Else
		DoWindow/F CircularAverage
	Endif
	
	TitleBox title0 title=simple_imagefolderpath,  fSize=14, pos={6,5}, frame=0
	SetVariable setvar0 title="X0 [pt]",pos={15,25},size={200,25},limits={-inf,inf,1},fSize=13, value=:Red2DPackage:U_X0
	SetVariable setvar1 title="Y0 [pt]",pos={15,50},size={200,25},limits={-inf,inf,1},fSize=13, value=:Red2DPackage:U_Y0
	SetVariable setvar2 title="SDD [m]",pos={15,75},size={200,25},limits={0,inf,0.1},fSize=13, value=:Red2DPackage:U_SDD
	SetVariable setvar3 title="Tilt_X [º]",pos={15,100},size={200,25},limits={-90,90,1},fSize=13, value=:Red2DPackage:U_tiltX, help={"-90 to 90º"}
	SetVariable setvar4 title="Tilt_Y [º]",pos={15,125},size={200,25},limits={-90,90,1},fSize=13, value=:Red2DPackage:U_tiltY, help={"-90 to 90º"}
	SetVariable setvar5 title="Lambda [A]",pos={15,150},size={200,25},limits={0,inf,0.1},fSize=13, value=:Red2DPackage:U_Lambda, help={"Cu = 1.5418A, Mo = 0.7107A"}
	SetVariable setvar6 title="Pixel Size [um]",pos={15,175},size={200,25},limits={0,inf,1},fSize=13, value=:Red2DPackage:U_PixelSize, help={"Pilatus = 172um, Eiger = 75um"}

	Button button0 title="Circular Average",size={150,23},pos={45,265}, fstyle=1, proc=ButtonProcCA
	Button button1 title="Bring Image to Front",size={150,22},pos={45,305}, proc=ButtonProcR2D_BringImageToFront_ca
	
	R2D_GetImageList_CA("")	// refresh Z_ImageList_CA for the listbox. Z_ImageList_CA is a 2D text wave containing the image and mask lists.
	ListBox lb listWave=:Red2DPackage:Z_ImageList_CA
	ListBox lb mode=2, frame=0, pos={240,5}, size={450,330}, fSize=13, widths={150,100}, userColumnResize=1, proc=ListControl_SelectMask_CA
	
	PopupMenu popup1 title="Set all mask", pos={15,200}, fSize=13, value=R2D_GetMaskList_simple(), proc=Update_MaskName_All_CA
	// when refresh above popup, the selection number will remain in old one. Therefore, when it exceeds current list, no selection appears.
	Execute/P/Q "PopupMenu popup1 pos={15,200}"  // a workaround about Igor's know bug for bodywidth option.
	
	CheckBox cb0 title="Solid Angle Correction", pos={15, 230}, fSize=13, variable=:Red2Dpackage:U_sac
	
//	SetdataFolder saveDFR
	SetDataFolder $savedDF
	
End


////////////////////////////////////////////////////////
//////////////////Button Actions////////////////////////
////////////////////////////////////////////////////////

Function Update_MaskName_All_CA(pa) : PopupMenuControl
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
			
			SVAR MaskName_All_CA = :Red2DPackage:U_MaskName_All_CA
			MaskName_All_CA = popStr // remeber current selection
			NVAR U_row_CA = :Red2DPackage:U_row_CA

//			If(WaveExists(:Red2DPackage:Z_ImageList_CA))
				wave/T Z_ImageList_CA = :Red2DPackage:Z_ImageList_CA
				Z_ImageList_CA[][1] = MaskName_All_CA		// change mask name in Z_ImageList_CA. 1st col image, 2nd col mask.
				Show2D(U_row_CA, Z_ImageList_CA)
//			Endif
			SetDataFolder saveDFR
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcCA(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			InitiateCircularAverage()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcR2D_BringImageToFront_ca(ba) : ButtonControl
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

Function R2D_CircularAverageWindowHook(s)
	STRUCT WMWinHookStruct &s
	
	Variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.

	switch(s.eventCode)
		case 0:	// window activated
			String ImageFolderPath = R2D_GetImageFolderPath()	// Get image datafolder even 1D folder is activated.
			If(strlen(ImageFolderPath) > 0)
				R2D_CircularAveragePanel()
				hookResult = 1
			Endif
			break		
	endswitch

	return hookResult	// If non-zero, we handled event and Igor will ignore it.
End



////////////////////////////////////////////////////////////////////
////////////////////////////////Mask////////////////////////////////
////////////////////////////////////////////////////////////////////

/// Get the list of mask waves (used also in r2d_simple_circularaverage.ipf)
Function/S R2D_GetMaskList_simple()
	/// Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and imagelist.
//	If(R2D_Error_ImagesExist() == -1)
//		Abort
//	Endif

	String ImageFolderPath = R2D_GetImageFolderPath()	// Get image datafolder even 1D folder is activated.
	If(strlen(ImageFolderPath) == 0)
		Abort "You may be in a wrong datafolder."
	Endif
	DFREF saveDFR = GetDataFolderDFR()	// get current datafolder. It could be image folder or 1D folder.
	SetDataFolder $ImageFolderPath		// move to image folder
	
	NewDataFolder/O :Red2DPackage:Mask																																							
	String masklist = "no mask;" + WaveList("*", ";", "DIMS:2,TEXT:0", :Red2DPackage:Mask)
	
	SetDataFolder saveDFR
	
	return masklist
	
End

/// Create a image/mask listwave for listbox
Function R2D_GetImageList_CA(matchStr)
	string matchStr
	
	// check if in the correct datafolder
////	If(R2D_Error_ImagesExist() == -1)
////		Abort
////	Endif
	// A better method to check error.
	String ImageFolderPath = R2D_GetImageFolderPath()	// Get image datafolder even 1D folder is activated.
	If(strlen(ImageFolderPath) == 0)
		Abort "You may be in a wrong datafolder."
	Endif
	DFREF saveDFR = GetDataFolderDFR()	// get current datafolder. It could be image folder or 1D folder.
	SetDataFolder $ImageFolderPath		// move to image folder
	
	// Get the image list
	R2D_CreateImageList(1)	// create a text wave containing a list of images in selected datafolder, 1 for name order
	wave/T Imagelist = :Red2DPackage:ImageList
	variable image_num = DimSize(Imagelist, 0)
		
	// Create a listwave for the imagelist for CA
	wave/T/Z Z_ImageList_CA = :Red2DPackage:Z_ImageList_CA
	if(WaveExists(Z_ImageList_CA))
		Duplicate/O/T Z_ImageList_CA, :Red2DPackage:Z_ImageList_CA_old	// save old listwave to retrieve mask info
	endif
	Make/O/T/N=(image_num,2) :Red2DPackage:Z_ImageList_CA = ""	// make a new empty listwave
	wave/T Z_ImageList_CA = :Red2DPackage:Z_ImageList_CA
	SetDimLabel 1, 0, ImageName, Z_ImageList_CA
	SetDimLabel 1, 1, MaskWave, Z_ImageList_CA
	Z_ImageList_CA[][0] = Imagelist[p]	// apply new imagelist
	Z_ImageList_CA[][1] = "no mask"	// initialize

	// set mask info to listwave
	wave/T/Z Z_ImageList_CA_old = :Red2DPackage:Z_ImageList_CA_old	// set reference to old listwave
	variable new_size = DimSize(Z_ImageList_CA,0)
	variable old_size = DimSize(Z_ImageList_CA_old,0)
	variable i
	if(WaveExists(Z_ImageList_CA_old))	// if old listwave exists
		for(i=0; i<new_size; i++)	// test for all rows in new listwave
			if(i < old_size)	// applys old listwave mask info
				Z_ImageList_CA[i][1] = Z_ImageList_CA_old[i][1]
			else	// if old listwave does not exist, set no mask
				Z_ImageList_CA[i][1] = "no mask"
			endif
		endfor
	endif
	
	SetDatafolder saveDFR
	
End

/// Dialog for user to select mask for individual image
Function/S R2D_SelectMaskDialog(masklist)
	string masklist
	string selected_mask

	Prompt selected_mask,"Wave",popup,masklist
	DoPrompt "Select mask wave",selected_mask
	if(V_flag)	// user canceled
		return ""
	endif
	
	Print selected_mask + " is selected."
	return selected_mask

End

/// Listbox control (used also in r2d_simple_circularaverage.ipf)
Function ListControl_SelectMask_CA(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	String userdata = lba.userdata

	
	if(row+1 > DimSize(listWave,0) || row < 0)  // prevent out of index error when user selects a row out of the list
		return -1
	Endif

//	If(R2D_Error_ImagesExist() == -1) // Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and imagelist.
//		Abort
//	Endif
	
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
		
			String ImageFolderPath = R2D_GetImageFolderPath()	// Get image datafolder even 1D folder is activated.
			If(strlen(ImageFolderPath) == 0)
				Abort "You may be in a wrong datafolder."
			Endif
			DFREF saveDFR = GetDataFolderDFR()	// get current datafolder. It could be image folder or 1D folder.
			SetDataFolder $ImageFolderPath		// move to image folder
		
			NVAR U_row_CA = :Red2DPackage:U_row_CA
			U_row_CA = row
			if(col == 0)
				// display image and mask
				Show2D(row, listWave)
			elseif(col == 1)
				// ask user if change mask (when mask column is selected)ge
				string masklist = R2D_GetMaskList_simple()
				string selected_mask = R2D_SelectMaskDialog(masklist)
				if(strlen(selected_mask))	// if mask name is longer than zero (user selected a mask)
					listWave[row][1] = selected_mask
				endif
			Show2D(row, listWave)
			SetDataFolder saveDFR
			
			endif
			break 
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch

	return 0
End

/// Show selected image and mask
Static Function Show2D(row, listWave)
	variable row
	wave/T listWave
	
	string SelImagePath = listWave[row][0]
	string SelMaskPath = ":Red2DPackage:Mask:" + listWave[row][1]
	wave SelImage = $SelImagePath
	wave/Z SelMask = $SelMaskPath
	string current_imagenamelist

	DoWindow IntensityImage // Check if there is a window named 2DImageWindow. Exist returns 1 else 0.	
	If(V_flag == 0) // Create a new image window with name as 2DImageWindow if not exists.
		PauseUpdate
		NewImage/K=1/N=IntensityImage SelImage
		ModifyImage/W=IntensityImage ''#0 ctab= {1,*,Turbo,0},log=1
		
		if(WaveExists(SelMask))	// sel mask might be "no mask", which does not exist.
			AppendImage/T/W=IntensityImage SelMask
			ModifyImage/W=IntensityImage ''#1 explicit=1, eval={0,0,0,0,0}, eval={1,60000,60000,60000,50000} // eval is color. (eval={value, red, green, blue [, alpha]})
		endif
		ResumeUpdate
	Else // Remove all images on the graph and append new one
		PauseUpdate
		String oldimage_List = ImageNameList("IntensityImage",";") // Get existing ImageName in the window ImageGraph
		variable oldimage_num = itemsInList(oldimage_List)
		string oldimage_name
		AppendImage/T/W=IntensityImage SelImage
		variable i
		for(i=0; i<oldimage_num; i++)	// remove images after appending new one to prevent weird behavior of igor pro image graph.
			oldimage_name = StringFromList(i,oldimage_List)	// remove from oldest images
			RemoveImage/Z/W=IntensityImage $oldimage_name
		endfor
		ModifyImage/W=IntensityImage ''#0 ctab= {1,*,Turbo,0},log=1
		
		if(WaveExists(SelMask))	// sel mask might be "no mask", which does not exist.
			AppendImage/T/W=IntensityImage SelMask
			ModifyImage/W=IntensityImage ''#1 explicit=1, eval={0,0,0,0,0}, eval={1,60000,60000,60000,50000} // eval is color. (eval={value, red, green, blue [, alpha]})
		endif
		ResumeUpdate
	Endif

End


//////////////////////////////////////////////////////////
//////////////////////Main Codes//////////////////////////
//////////////////////////////////////////////////////////

/// Prepare for circular average
Function InitiateCircularAverage([mask_path])
	string mask_path	// the optional parameter is used in auto process. Do not delete it from the ().

	/// Check if in the image folder.
//	If(R2D_Error_ImagesExist() == -1)
//		Abort
//	Endif
	String ImageFolderPath = R2D_GetImageFolderPath()	// Get image datafolder path. This works even 1D folder is selected.
	If(strlen(ImageFolderPath) == 0)
		Abort "You may be in a wrong datafolder."
	Endif
	SetDataFolder $ImageFolderPath		// set datafolder to image folder.
	
	DoWindow/H
	Print "Prepare to circular-average..."
	Doupdate
	variable t1=StartMsTimer // Start Timer

	/// Create a new folder to store the generated 1D data.
	variable i
	string dfname
	
	dfname = UniqueName("Iq1D",11,0)
	NewDataFolder $dfname
	string df1d = GetDataFolder(1, $dfname)
			
	/// Get global variables for the following procedures.
	NewDataFolder/O Red2DPackage	// just in case
	Wave/T ImageList = :Red2DPackage:ImageList
	Variable numOfImages = DimSize(ImageList,0)
	Wave TopImage = $ImageList[0]
						
	NVAR U_Xmax = :Red2DPackage:U_Xmax
	NVAR U_Ymax = :Red2DPackage:U_Ymax
	NVAR U_Lambda = :Red2DPackage:U_Lambda
	U_Xmax = Dimsize(TopImage,0) - 1		// These global variables are used in clac_q and circular average.
	U_Ymax = Dimsize(TopImage,1) - 1
			
   /// Calculate q at each pixel, using the info in Red2Dpackage. Solid angle correction factor is generated as well.
	R2D_calc_qMap()
	NVAR U_qres = :Red2DPackage:U_qres
	NVAR U_qmin = :Red2DPackage:U_qmin
	NVAR U_qnum = :Red2DPackage:U_qnum

  	/// Calculate 1D qq and twotheta. Circular average function will duplicate these waves as qwave for each _i wave.
	make/O/D/N=(U_qnum) :Red2DPackage:qq, :Red2DPackage:twotheta
	wave qq = :Red2DPackage:qq
	wave twotheta = :Red2DPackage:twotheta
	qq = U_qmin + U_qres*p
	twotheta = 2*asin(qq/4/pi*U_Lambda)/pi*180
	// remove unnecessary points to make the graph beautiful.
	// NOTE: the number of points deleted here must match the points in "CircularAverage" function.
	DeletePoints U_qnum-5, 5, qq
	DeletePoints U_qnum-5, 5, twotheta
	DeletePoints 0, 1, qq
	DeletePoints 0, 1, twotheta
	
	Print "Circular-average initialized in ", StopMSTimer(t1)/1E+6, "sec." //End Timer	
	
	//////////////////Start circular average///////////////
	wave/T Z_ImageList_CA = :Red2DPackage:Z_ImageList_CA
	Variable t0
	For(i=0; i<numOfImages; i++)
		t0=StartMsTimer // Start Timer
		if(ParamIsDefault(mask_path))	// if mask_path is not specified
			mask_path = ":Red2DPackage:Mask:"+Z_ImageList_CA[i][1]
		endif
		CircularAverage($(ImageList[i]), df1d, $mask_path) // Do circular average
		Print i+1,"/",numOfImages, ";", StopMSTimer(t0)/1E+6, "sec/image" //End Timer	
	Endfor

	SetDataFolder $dfname
	Print "Circular-average completed."
	
End


/// *** Calculate q, theta, solid angle map of the scattering image
/// Use Euler angles to calcualte the theta and q
Function R2D_calc_qMap()

	/// Check if in the image folder.
	String ImageFolderPath = R2D_GetImageFolderPath()	// Get image datafolder even 1D folder is activated.
	If(strlen(ImageFolderPath) == 0)
		Abort "You may be in a wrong datafolder."
	Endif
		
	/// Move to R2D package folder
	SetDataFolder $ImageFolderPath		// set datafolder to image folder
	SetDataFolder Red2DPackage

	Variable/G U_Xmax, U_Ymax, U_X0, U_Y0, U_SDD, U_Lambda, U_PixelSize, U_tiltX, U_tiltY, U_tiltZ, U_qnum, U_qres, U_qmin, U_theta_res, U_L0
	Variable/G U_qx_index_min, U_qx_index_max, U_qx_index_num
	Variable/G U_qy_index_min, U_qy_index_max, U_qy_index_num
	Variable/G U_qz_index_min, U_qz_index_max, U_qz_index_num
	
	If(U_X0 == 0 && U_Y0 == 0)
		DoAlert 0, "Beam center (X0, Y0) = (0, 0). Proceed anyway?"
		return -1
	elseif(numtype(U_X0) == 2 || numtype(U_Y0) == 2 )
		DoAlert 1, "Beam center is not defined. Please use the Fit Standard or Circular Average panel to set the beam center (X0, Y0), SDD, wavelength, and pixel size."
		return -1
	endif

	/// make rotation matrix
	variable Xrad, Yrad, Zrad
	Xrad = U_tiltX/180*pi
	Yrad = U_tiltY/180*pi
	Zrad = U_tiltZ/180*pi
	Make/D/O/N=(3,3) RotationMatrix
	
	RotationMatrix[0][0] = cos(Yrad)
	RotationMatrix[1][0] = sin(Xrad)*sin(Yrad)
	RotationMatrix[2][0] = -cos(Xrad)*sin(Yrad)
	RotationMatrix[0][1] = sin(Yrad)*sin(0)
	RotationMatrix[1][1] = cos(Xrad)*cos(0)-cos(Yrad)*sin(Xrad)*sin(0)
	RotationMatrix[2][1] = cos(0)*sin(Xrad)+cos(Xrad)*cos(Yrad)*sin(0)
	RotationMatrix[0][2] = cos(0)*sin(Yrad)
	RotationMatrix[1][2] = -cos(Xrad)*sin(0)-cos(Yrad)*cos(0)*sin(Xrad)
	RotationMatrix[2][2] = cos(Xrad)*cos(Yrad)*cos(0)-sin(Xrad)*sin(0)
		
	/// make unit vector in roated plane
	Make/FREE/D/O/N=3 xvec, yvec, zvec, pvec, qvec
	xvec = {1,0,0} 
	yvec = {0,1,0}
	zvec = {0,0,1}
	MatrixOP/FREE/O avec = RotationMatrix x xvec
	MatrixOP/FREE/O bvec = RotationMatrix x yvec
	MatrixOP/FREE/O nvec = RotationMatrix x zvec
	
	/// make q Matrix and solidangle correction matrix
//	variable theta_res, L0	
	U_theta_res = atan(U_PixelSize*1E-6/U_SDD) // define resolution of scattering angle [radian] using the center pixel
	U_qres = 4*pi/U_Lambda*sin(U_theta_res/2) // convert theta_res to the resolution of scattering vector [A]
	U_L0 = U_SDD*abs(MatrixDot(zvec, nvec))/MatrixDot(nvec,nvec) // a formula to get distance from a point to a plane, using the normal vector.
	// See titled detector issue.docx for detail derivation
	
	Make/D/O/N=(U_Xmax+1,U_Ymax+1,3) pvecMap, qvecMap // 2D vector maps; each beam contains the vector values.
	Make/D/O/N=(U_Xmax+1,U_Ymax+1) qScalarIndexMap, t2map, SolidAngleMap, t2map_geo	// 2D scalar maps
	
	// pixel vector and scalar map. For detail, see titled detector issue.docx.
	Multithread pvecMap = (p-U_X0)*avec[r]*U_PixelSize*1E-6 + (q-U_Y0)*bvec[r]*U_PixelSize*1E-6 + U_SDD*zvec[r]
	MatrixOP/O pscalarMap = sqrt(pvecMap[][][0]*pvecMap[][][0] + pvecMap[][][1]*pvecMap[][][1] + pvecMap[][][2]*pvecMap[][][2])
	
	// q vector and scalar map. For detail, see titled detector issue.docx.
	Multithread qvecMap = 2*pi/U_Lambda*(pvecMap[p][q][r]/pscalarMap[p][q]-zvec[r])
	MatrixOP/O qscalarMap = sqrt(qvecMap[][][0]*qvecMap[][][0] + qvecMap[][][1]*qvecMap[][][1] + qvecMap[][][2]*qvecMap[][][2])
	U_qmin = WaveMin(qscalarMap)	// min value of q scalar
	
	// qScalarIndexMap; index starts from 1
	Multithread qScalarIndexMap = round(qscalarMap/U_qres) - round(U_qmin/U_qres)
	U_qnum = WaveMax(qScalarIndexMap) + 1 //qScalarIndexMap starts from 0
//	variable qindex_min = WaveMin(qScalarIndexMap)
//	Multithread qScalarIndexMap -= qindex_min

	// q vector index map @New at 2023-03-12
	MatrixOP/O qVecIndexMap = round(qvecMap/U_qres)
	MatrixOP/FREE/O qxindexmap = qVecIndexMap[][][0]
	MatrixOP/FREE/O qyindexmap = qVecIndexMap[][][1]
	MatrixOP/FREE/O qzindexmap = qVecIndexMap[][][2]
	U_qx_index_min = WaveMin(qxindexmap)
	U_qx_index_max = WaveMax(qxindexmap)
	U_qx_index_num = U_qx_index_max - U_qx_index_min + 1
	U_qy_index_min = WaveMin(qyindexmap)
	U_qy_index_max = WaveMax(qyindexmap)
	U_qy_index_num = U_qy_index_max - U_qy_index_min + 1
	U_qz_index_min = WaveMin(qzindexmap)
	U_qz_index_max = WaveMax(qzindexmap)
	U_qz_index_num = U_qz_index_max - U_qz_index_min + 1
	
	Make/O/FREE qvec_min = {U_qx_index_min, U_qy_index_min, U_qz_index_min}
	Duplicate/O qVecIndexMap, qVecIndexMap_withOffset
	Multithread qVecIndexMap_withOffset = qVecIndexMap[p][q][r] - qvec_min[r]	// subtract qx_min, qy_min, qz_min, from x-layer, y-layer, and z-layer of qvecIndexMap.
	
	// 2 theta map
	t2map = 2*asin(qScalarMap*U_lambda/(4*pi))
	
	// 2025-10-11 I have confirmed that t2map and t2map_geo contain are identical at all pixel positions.
//	variable costheta
//	variable i, j
//	for(i=0; i<U_Xmax+1; i++)
//		for(j=0; j<U_Ymax+1; j++)
//			MatrixOP/FREE pvec = beam(pvecmap, i, j)	// get beam, the p_vector in the pixel_ij
//			costheta = MatrixDot(pvec, zvec)/norm(pvec) // calcualte dot product
//			t2map_geo[i][j] = acos(costheta)	// calculate angle
//		endfor
//	endfor
	
	// Solid angle map
	Multithread SolidAngleMap = (U_L0/pscalarMap)^3 // Solid angle ratio to the center pixel
//	Multithread SolidAngleMap = U_PixelSize^2*1E-12/L0^2*1E+9 * (L0/pscalarMap)^3 //Correction factor to convert I/pixel to I/Solid angle. The last 1E+9 converts to nano solid angle.
//	Multithread SolidAngleMap = U_PixelSize^2*1E-12 * MatrixDot(nvec, pvecMap) / pscalarMap^3 * 1E+9 //modified for tilted detectors.
	
	/// Move back to image folder.
//	SetdataFolder saveDFR
	SetDataFolder $ImageFolderPath
	
End

/// Circular average
//ThreadSafe Static Function CircularAverage(pWave, df1d, mask_wave)
Static Function CircularAverage(pWave, df1d, mask_wave)
	Wave pWave
	string df1d
	wave/Z mask_wave
	
	/// Set global variables, which are shared with the other procedures. 
	NVAR Xmax = :Red2DPackage:U_Xmax
	NVAR Ymax = :Red2DPackage:U_Ymax
	NVAR qnum = :Red2DPackage:U_qnum
	Wave qScalarIndexMap = :Red2DPackage:qScalarIndexMap
	Wave SolidAngleMap = :Red2DPackage:SolidAngleMap
	
	NVAR U_sac = :Red2Dpackage:U_sac
	
	/// Setup for mask
	If(!WaveExists(mask_wave))	// if the selected wave does not exist or user did not select a mask wave
		Duplicate/FREE/O qScalarIndexMap, mask_wave	// manually make a mask wave
		mask_wave = 0	// 0 means no masking
//		Print "no mask"
	Endif

	/// Create a histogram of I vs q
	variable cir_pix_num = 8*Xmax + 8*Ymax	// a square must be larger than a circle inside that. 2025-11-19 not enough and increaset from 2 to 3.
	make/FREE/D/O/N=(qnum, cir_pix_num) Iq_hist, s2q_hist	// make a histogram of intensity vs q and error vs q	
	make/FREE/D/O/N=(qnum) Iq_count = 0	// make a counter wave to remember the number of added pixels in each column of the histogram
	
	///
	variable i, j, qindex, count
	for(i=0; i<Xmax+1; i++) //Xmax is the coordinates.
		for (j=0; j<Ymax+1; j++)
   			if(numtype(pWave[i][j]) == 2 || mask_wave[i][j] == 1)
   				//skip add when the pixel is NaN or mask wave is 1.
    		else
   			qindex = qScalarIndexMap[i][j] //qScalarIndexMap multiplying q_resolution yiealds the q values
   			count = Iq_count[qindex]	//get the count number of the qindex
   			
   			if(U_sac)	
		 	  	 	Iq_hist[qindex][count] = pWave[i][j]/SolidAngleMap[i][j] // Rearrange xy graph to I-q histogram. I is corrected to int per solid angle
		 	  	 	s2q_hist[qindex][count] = pWave[i][j]/SolidAngleMap[i][j]^2	// err^2 = (pWave^0.5 per SolidAngle)^2
	 	  	 	else
	 		  	 	Iq_hist[qindex][count] = pWave[i][j] 	// Rearrange xy graph to I-q histogram. No solid angle correction
	 	  		 	s2q_hist[qindex][count] = pWave[i][j]	// err^2. No solid angle correction. 	 	
	 	  		endif
				Iq_count[qindex] += 1 //calculate the pixel number that corresponds to distance r, considering the mask.
				
			endif
		endfor
	endfor
	
	/// Get mean and standard deviation of each q-column of histogram
	MatrixOP/FREE/O Iq_sum = sumRows(Iq_hist)	// get total count per solid angle per q
	MatrixOP/FREE/O intensity = Iq_sum/Iq_count	// get average intensity per solid angle per q
	MatrixOP/FREE/O s2q_sum = sumRows(s2q_hist)	// get square of error per solid angle per q
	MatrixOP/FREE/O int_err = sqrt(s2q_sum)/Iq_count	// get photon counting error
	Multithread intensity = intensity == 0 ? NaN : intensity	// convert zero count q to NaN since 2023-04-11
	Multithread int_err = int_err == 0 ? NaN : int_err // convert zero count q to NaN since 2023-04-11
	
//	Duplicate/FREE/O Iq_hist, delta_I
//	Multithread delta_I = Iq_hist == 0 ? 0 : (Iq_hist-Iq_sum[p])^2  // calculate I(q) - I(q)ave
//	MatrixOP/FREE/O exp_err0 = sumRows(delta_I)/(Iq_count*(Iq_count-1))
//	MatrixOP/FREE/O exp_err = sqrt(exp_err0)	// get experimental error
//	MatrixOP/O err = maxAB(int_err,int_err_2)

//	for(i=0; i<qnum; i++)
//		// extract ith row
//		MatrixOP/O/FREE 
//		// redimension the row to a 1D wave with count's elements
//		// calculate mean
//		// calcualte sqrt/count, photon counting error
//		// calculate stdv, experimental error
//		
//	endfor
	
	DeletePoints qnum-5, 5, intensity
	DeletePoints qnum-5, 5, int_err
	DeletePoints 0, 1, intensity
	DeletePoints 0, 1, int_err
	
	string newIntName = df1d + NameofWave(pWave) + "_i"
	string newInterrName = df1d + NameofWave(pWave) + "_s"
	string newQName = df1d + NameofWave(pWave) + "_q"
	string newTwothetName = df1d + NameofWave(pWave) + "_2t"
	duplicate/O/D intensity $newintname
	duplicate/O/D int_err $newinterrname
	duplicate/O/D :Red2DPackage:qq $newQName
	duplicate/O/D :Red2DPackage:twotheta $newTwothetName
	
End


///2019-11-13
///The intensity scatterec on a pixel of the detector depends on 1) the distance from the sample to the pixel and 2) the solid angle of the pixel.
///The solid angle "difference" is corrected in this procedure using I_corr = I_raw * (Lp/L0)^3, where Lp is the distance from the sample to the pixel
///and the L0 is the normal distance from the sampel to the detector plane.
///REF: Pauw, B. R. Everything SAXS: Small-Angle Scattering Pattern Collection and Correction. J Phys Condens Matter 2013, 25, 383201.
///The intensity has been further normalized as "intensity per solid angle" by dividing I_corr with solid angle (pixel size^2/L0^2).

///2020-03-02
///1D data format was changed to NIST q, I, Ierr format.

///2021-03-28
///The description in 2019-11-13 is a bit wrong. Intensity per pixel depends only on the solid angle of the pixel and the correction
///has been allways performed only for solid angle.
///The correction is I_corr = I_raw * (Lp/L0)^3 / (pixel size^2/L0^2)


///2021-05-20
///There is another technique to estimate the uncertainty of the scattering intensity by calculating the standard error of mean of the pixel intensities.
///I have implemented in Red2D v2.2.1, but both technique resulted in the exactly the same result, except when the pixel number is very small.