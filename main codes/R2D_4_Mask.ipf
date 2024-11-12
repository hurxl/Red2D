#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// *************************
// *** Mask GUI ***
// *************************
Function R2D_MaskPanel()
	/// Check if in images folder by checking if there is an imagelist in the package folder.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif	

	/// Set global variables, which are shared with the other procedures.
	NewDataFolder/O Red2DPackage
	Variable/G :Red2DPackage:U_phi0
	Variable/G :Red2DPackage:U_dphi
	Variable/G :Red2DPackage:U_X0
	Variable/G :Red2DPackage:U_Y0
	Variable/G :Red2DPackage:U_maskthreshold
	Variable/G :Red2DPackage:U_maskEdgeSize
	
	/// Check if panel exist
	DoWindow MaskPanel
	If(V_flag == 0)
		NewPanel/K=1/N=MaskPanel/W=(200,200,1270,480)
		SetWindow MaskPanel, hook(MaskHook) = R2D_MaskWindowHook	
	Else
		DoWindow/F MaskPanel
	Endif
	
	// threshold mask GUI
	TitleBox title0, pos={50,10}, frame=0, fSize=13, title="Threshold Mask (use ROI to limit region)"
	SetVariable setvar0 title="Threshold [count]",pos={30,40},size={180,25},limits={-inf,+inf,1},fSize=13, value=:Red2DPackage:U_maskthreshold
	SetVariable setvar1 title="Extended Edge [px]",pos={235,40},size={170,25},limits={0,+inf,1},fSize=13, value=:Red2DPackage:U_maskEdgeSize
	Button button0 title="New TH Mask (Below)",pos={425,37},size={145,23},proc=ButtonProcMakeThresholdMask_below
	Button button8 title="New TH Mask (Above)",pos={425,10},size={145,23},proc=ButtonProcMakeThresholdMask_above

	
	// sector mask GUI
	TitleBox title1, pos={95,90}, frame=0, fSize=13, title="Sector Mask"
	SetVariable setvar2 title="X0 [pt]",pos={30,120},size={210,25},limits={-inf,+inf,1},fSize=13, value=:Red2DPackage:U_X0
	SetVariable setvar3 title="Y0 [pt]",pos={30,145},size={210,25},limits={-inf,+inf,1},fSize=13, value=:Red2DPackage:U_Y0
	SetVariable setvar4 title="φ0 [º]",pos={30,170},size={210,25},limits={0,360,1},fSize=13, value=:Red2DPackage:U_phi0, help={"phi0 should be in range of 0 - 180."}
	SetVariable setvar5 title="Δφ [º]",pos={30,195},size={210,25},limits={0,360,1},fSize=13, value=:Red2DPackage:U_dphi, help={"dphi should be in range of 0 - 180."}
	Button button1 title="New Sector Mask",pos={20,235},size={130,23},proc=ButtonProcMakeSectorMask
	CheckBox cb1 title="Pair Sector", pos={165, 228}, fSize=13
	CheckBox cb2 title="Reverse Mask", pos={165, 247}, fSize=13

	
	// roi mask GUI
	TitleBox title2, pos={420,90}, frame=0, fSize=13, title="ROI Mask"
	TitleBox title3, pos={317,120}, frame=5, fSize=13
	TitleBox title3, title=" 1. Display your image\r\r 2. Go Igor menu 'Image' → 'Image ROI...' \r \r 3. Draw ROI (region of interest)"
	Button button2 title="New ROI Mask",pos={320,235} ,size={130,23}, proc=ButtonProcCreROIMask
	CheckBox cb0 title="Reverse ROI", pos={480, 238}, fSize=13, proc=CheckBoxProc_reversedmask

	
	// list GUI
	R2D_GetMaskList("")
	wave/T Z_MaskList = :Red2DPackage:Z_MaskList
	wave Z_MaskStatus = :Red2DPackage:Z_MaskStatus
	ListBox List0 win = MaskPanel, listWave=Z_MaskList, selWave=Z_MaskStatus, proc=ListControl_SelectMask
	ListBox List0 win = MaskPanel, mode=1, size={250,250}, pos={625,15}, fSize=13, widths={25,205}, userColumnResize=1

	// misc
//	TitleBox title3, pos={930,15}, frame=0, fSize=13, title="Merge or Delete\rSelected Masks"
	Button button3 title="Rename",size={130,23},pos={900,30},proc=ButtonProcRenameMask
	Button button4 title="Save As",size={130,23},pos={900,75},proc=ButtonProcSaveMaskAs
	Button button5 title="Merge",size={130,23},pos={900,120},proc=ButtonProcMergeMasks
	Button button6 title="Delete",size={130,23},pos={900,165},proc=ButtonProcDeleteMask
	Button button7 title="Refresh",size={80,23},pos={925,235},proc=ButtonProcRefreshMask

	// Decoration
//	DrawLine/W=MaskPanel 280,30,280,300
	GroupBox group0 pos={50,75},size={500,2}
	GroupBox group1 pos={280,90},size={2,180}
	GroupBox group2 pos={600,20},size={2,250}
	
End


// *************************
// *** Button Actions ***
// *************************
Function ButtonProcMakeThresholdMask_below(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NVAR threshold = :Red2DPackage:U_maskthreshold
			NVAR EdgeSize = :Red2DPackage:U_maskEdgeSize
			
			DoWindow IntensityImage
			if(V_flag == 0)
				Abort "IntensiytImage window does not exist. Try to use Display Images to make a new image window."
			endif
			R2D_MakeThresholdMask(threshold, EdgeSize, "below")
		 	R2D_GetMaskList("")
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProcMakeThresholdMask_above(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NVAR threshold = :Red2DPackage:U_maskthreshold
			NVAR EdgeSize = :Red2DPackage:U_maskEdgeSize
			
			DoWindow IntensityImage
			if(V_flag == 0)
				Abort "IntensiytImage window does not exist. Try to use Display Images to make a new image window."
			endif
			R2D_MakeThresholdMask(threshold, EdgeSize, "above")
		 	R2D_GetMaskList("")
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProcMakeSectorMask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			DoWindow IntensityImage
			if(V_flag == 0)
				Abort "IntensiytImage window does not exist. Try to use Display Images to make a new image window."
			endif

			ControlInfo/W=MaskPanel cb1
			variable pairflag = V_Value // 0 single, 1 pair
			ControlInfo/W=MaskPanel cb2
			variable reverseflag = V_Value // 0 normal, 1 reversed
			MakeSectorMask(pairflag, reverseflag)
		 	R2D_GetMaskList("")
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProcRefreshMask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			R2D_MaskPanel() // when refresh is specified, no matter what value, it is ture.
		 
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProcSaveMaskAs(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			R2D_SaveMaskAs()
			R2D_GetMaskList("")
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProcRenameMask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			R2D_RenameMask()
			R2D_GetMaskList("") 
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProcCreROIMask(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			DoWindow IntensityImage
			if(V_flag == 0)
				Abort "IntensiytImage window does not exist. Try to use Display Images to make a new image window."
			endif
			ControlInfo/W=MaskPanel cb0
			variable reversedROI = V_Value // checked for ture
			ConvertROI2Mask(rev=reversedROI)
			R2D_GetMaskList("")	
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function CheckBoxProc_reversedmask(cba) : CheckBoxControl
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

Function ButtonProcDeleteMask(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			R2D_DeleteMask()
			R2D_GetMaskList("")
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProcMergeMasks(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			R2D_MergeMasks()
			R2D_GetMaskList("")
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function R2D_MaskWindowHook(s)
	STRUCT WMWinHookStruct &s
	
	Variable hookResult = 0	// 0 if we do not handle event, 1 if we handle it.

	switch(s.eventCode)
		case 0:	// window activated

			If(R2D_Error_ImagesExist(NoMessage = 1) == 0)
				R2D_MaskPanel()
				hookResult = 1				
			Endif	

			break		
	endswitch

	return hookResult	// If non-zero, we handled event and Igor will ignore it.
End


// *************************
// *** Main Codes ***
// *************************
// Create Sector Mask
Static Function MakeSectorMask(pairflag, reverseflag)
	variable pairflag	// 0 single, 1 pair
	variable reverseflag // 0 normal, 1 reversed
	
	//Check if in images folder
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
//	DoWindow IntensityImage
//	if(V_flag == 0)
//		Abort "IntensiytImage window does not exist. Try to use Display Images to make a new image window."
//	endif
			
	//Get Top Image
	String ImageList = ImageNameList("IntensityImage",";")
	String TopImageName = StringFromList(0, ImageList,";")
	Wave TopImage = $(TopImageName)
				
	//Set global variables, which are shared with the other procedures. 
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
	NewDataFolder/O Mask
	Variable/G U_Xmax, U_Ymax, U_X0, U_Y0, U_phi0, U_dphi
			
	//Calcualte Xmax and Ymax again in case.
	U_Xmax=Dimsize(TopImage,0)-1
	U_Ymax=Dimsize(TopImage,1)-1
	
	//Duplicate Top Image as SectorMask and save it in package folder.
	Duplicate/O TopImage, :Mask:SectorMask
	Wave SectorMask = :Mask:SectorMask
	Multithread SectorMask = 0	//1 denotes the pixels to be masked. denotes the pixels to be used.
			
	//Create SectorMask
	variable i, j
	variable/C z
	variable phi, pairphi
	For(i=0; i<U_Xmax+1; i+=1) //gXmax is the coordinates.
		For(j=0; j<U_Ymax+1; j+=1)
			// Get the polar cordinate of the selected pixcel.
			z = r2polar(cmplx(i-U_X0,-j+U_Y0))
			phi = imag(z)/pi*180
	    			
			// Change 0->+180, 0->-180 style to 0->+360 sytle
   		If(phi<0)
   			phi +=360
   		Endif
    				
   	 	// Type 0 into SectorMask when phi in range.
    		If(U_phi0 - U_dphi/2 < 0 && phi >= U_phi0 - U_dphi/2 + 360)	// when the low limit is negative: (-* ~ -0) -> (* ~ +360)
    			SectorMask[i][j] = 1
    		Elseif(U_phi0 + U_dphi/2 > 360 && phi <= U_phi0 + U_dphi/2 - 360)	// when the high limit is over 360: (360 ~ 360+*) -> (0 ~ *)
    			SectorMask[i][j] = 1
    		Elseif(U_phi0 - U_dphi/2 <= phi && phi <= U_phi0 + U_dphi/2)	// when the limits are in range of 0~360
   			SectorMask[i][j] = 1
   		Endif
   		
   		If(pairflag == 1)
   			pairphi = U_phi0 + 180
   			if(pairphi > 180)
   				pairphi = U_phi0 - 180
   			endif
	    		If(pairphi - U_dphi/2 < 0 && phi >= pairphi - U_dphi/2 + 360)	// when the low limit is negative: (-* ~ -0) -> (* ~ +360)
	    			SectorMask[i][j] = 1
	    		Elseif(pairphi + U_dphi/2 > 360 && phi <= pairphi + U_dphi/2 - 360)	// when the high limit is over 360: (360 ~ 360+*) -> (0 ~ *)
	    			SectorMask[i][j] = 1
	    		Elseif(pairphi - U_dphi/2 <= phi && phi <= pairphi + U_dphi/2)	// when the limits are in range of 0~360
	   			SectorMask[i][j] = 1
	   		Endif
			Endif
   			
		Endfor
	Endfor
	
	// reverse mask
	if(reverseflag)
		Multithread SectorMask = SectorMask[p][q] > 0 ? 0 : 1
	endif
		 
	//Append M_SectorMask to Top Image
	RemoveImage/Z SectorMask //ImageName is the actual Image Name, not the wave name
	AppendImage/T SectorMask //When appending it should be wave name
	ModifyImage SectorMask explicit=1, eval={0,0,0,0,0}, eval={1,60000,60000,60000,50000} // eval is color. (eval={value, red, green, blue [, alpha]})

	SetDataFolder saveDFR
	
End


/// Create ROI Mask
Static Function ConvertROI2Mask([rev])
	variable rev  // 1 to reverse the mask

	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	///////////////Convert ROI to mask/////////////////
	String TopImage = StringFromList(0, ImageNameList("IntensityImage",";"),";")
	ImageGenerateROIMask $TopImage // Convert ROI to mask (1 for ROI(mask) and 0 for the others)
	Wave refmask = M_ROIMask // ROI mask is stored in a wave "ROIMask"
	
	If(rev == 1)
		Multithread refmask = refmask == 1 ? 0 : 1  // reverse the mask
	Endif
	
	Duplicate/O refmask, :Red2Dpackage:MasK:ROIMask
	Wave ROIMask = :Red2Dpackage:Mask:ROIMask

	//Append M_ROIMask to Top Image
	RemoveImage/Z ROIMask
	AppendImage/T ROIMask
	ModifyImage ROIMask explicit=1, eval={0,0,0,0,0}, eval={1,60000,60000,60000,50000} // eval is color. (eval={value, red, green, blue [, alpha]})
	
	Killwaves refmask
	
End

//Static Function ConvertNonROI2Mask()
//
//	If(R2D_Error_ImagesExist() == -1)
//		Abort
//	Endif	
//
//	///////////////Convert non-ROI area to mask/////////////////
//	String TopImage = StringFromList(0, ImageNameList("ImageNameList",";"),";")
//	ImageGenerateROIMask $TopImage // Convert ROI to mask (1 for ROI and 0 for the others)
//	wave M_ROIMask
//	
//	Duplicate/O M_ROIMask, :Red2Dpackage:ROIMask  // M_ROImask generated by ImageGenerateROIMask
//	Wave ROIMask = :Red2Dpackage:ROIMask
//	Killwaves M_ROIMask
//	
//	//Invert mask
//	Multithread ROIMask = ROIMask == 1 ? 0 : 1  // if roi_mask = 1, change it to 0, and vice versa
//
//	//Append M_ROIMask to Top Image
//	RemoveImage/Z ROIMask
//	AppendImage/T ROIMask
//	ModifyImage ROIMask explicit=1, eval={0,0,0,0,0}, eval={1,60000,60000,60000,50000} // eval is color. (eval={value, red, green, blue [, alpha]})
//	
//End


/// Create threshold mask

Function R2D_MakeThresholdMask(threshold, EdgeSize, type)
	variable threshold
	variable EdgeSize
	string type

	If(R2D_Error_ImagesExist() == -1)	// check if in correct datafolder
		Abort
	Endif
	
	// 2024-11-10 I do not know why this complicated code was used.
	// get top image except masks
//	string image_namelist = SortList(ImageNameList("IntensityImage",";"),";",1)	// get all image names from the specified graph
//	variable image_number = itemsInList(Image_namelist)
//	string dfr_name
//	string image_name
//	string topimage_name
//	variable i
//	for(i=0; i<image_number; i++)	// get all wave stored in red2dpackage:mask:
//		image_name = StringFromList(i, image_namelist)
//		wave image_wave = ImageNameToWaveRef("IntensityImage", image_name)	// set reference for image wave on graph
//		dfr_name = GetWavesDataFolder(image_wave,1)	// get full path of the wave, no wave name
//		if(!StringMatch(dfr_name, "*:Red2DPackage:Mask:"))
//			wave TopImage = image_wave	// this is the first non-mask image
//			topimage_name = NameOfWave(TopImage)
//			break
//		endif
//	endfor
	string image_namelist = ImageNameList("IntensityImage",";")
	string topimage_name = StringFromList(0, image_namelist)
	wave/Z TopImage = $topimage_name
	
	If(!waveexists(TopImage))
		Print "no image found"
		Abort "No image found on IntensityImage window."
	Endif
	
	// Create ROI if exists
	ImageGenerateROIMask/W=IntensityImage/E=1/I=0 $topimage_name	// ImageGenerateROIMask does not directly accept wave, it needs instance name
	// by default ImageGenerateROIMask creates a mask wave, by using /E=1/I0 to make it ROI wave or mask outsie of ROI.
	wave/Z M_ROIMask
	
	// Apply threshold
	if(V_flag)	// if roi exists
		if(stringmatch(type, "below"))
			ImageThreshold/Q/M=0/I/T=(threshold)/R={M_ROIMask, 0} TopImage
		else
			ImageThreshold/Q/M=0/T=(threshold)/R={M_ROIMask, 0} TopImage
		endif
		// By default ImageThreshold maps pixel above the threshold as 255, below as 0, NaN as 64.
		// I inserted /I to flip this creteria. So, above threshold becomes 0, and below becomes 255.
		// 0 for pixel no need to mask, 255 for pixels want to mask.
		// 2024-06-17 An option added to set threshold above a value, using a string "type". Type could be "below" or "above".
	else	// if roi does not exist
		if(stringmatch(type, "below"))
			ImageThreshold/Q/M=0/I/T=(threshold) TopImage
		else
			ImageThreshold/Q/M=0/T=(threshold) TopImage
		endif
	endif
	wave M_ImageThresh // M_ImageThresh 
	Multithread M_ImageThresh = M_ImageThresh < 100 ? 0 : 255 // NaN was saved as 63; change them to 0.
	if(EdgeSize > 0)
		EdgeSize = EdgeSize*2-1	// convert 1,2,3... to 1,3,5...
		MatrixFilter/N=(EdgeSize) gauss M_ImageThresh	// slightly enlarge the mask area using gauss convolution (blurring the edge)
	endif
		
	Duplicate/O M_ImageThresh, :Red2Dpackage:MasK:ThreshMask
	wave ThreshMask = :Red2Dpackage:MasK:ThreshMask
	Multithread ThreshMask = M_ImageThresh > 5 ? 1 : 0 // in R2D, 1 denotes pixels to be masked and 0 for non-masked pixel														
	
	//Append M_ROIMask to Top Image
	RemoveImage/W=IntensityImage/Z ThreshMask
	AppendImage/W=IntensityImage/T ThreshMask
	ModifyImage/W=IntensityImage ThreshMask explicit=1, eval={0,0,0,0,0}, eval={1,60000,60000,60000,50000} // eval is color. (eval={value, red, green, blue [, alpha]})

	
	KillWaves M_ImageThresh, M_ROIMask
	
End

/// Save mask
Function R2D_SaveMaskAs()

	/// Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and imagelist.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	// get mask list and status list
	wave/T Z_MaskList = :Red2DPackage:Z_MaskList
	wave Z_MaskStatus = :Red2DPackage:Z_MaskStatus
	variable mask_num = DimSize(Z_MaskList,0)
	
	// if a mask is selected, prompt a dialog to rename the mask, if no mask selected, abort
	variable i
	variable count = 0
	variable selectedindex
	string mask_path
	string newmask_name
	string newmask_path
	For(i=0; I<mask_num; i++)
		if(Z_MaskStatus[i][0] == 2^5+2^4)	// if check box is checked
			selectedindex = i
			count ++
		endif
	Endfor
	if(count == 0)	// no mask is selected
		Abort "No mask is selected"
	elseif(count > 1)	// more than one masks is selected
		Abort "More than one masks are selected. Please select one mask a time."
	elseif(count == 1)
		mask_path = ":Red2DPackage:Mask:"+Z_MaskList[selectedindex][1]
		newmask_name = R2D_MaskNameDialog()
		newmask_path = ":Red2DPackage:Mask:" + newmask_name
		if(strlen(newmask_name) == 0)
			Print "User canceled"
			return -1	// user canceled
		endif
		if(WaveExists($newmask_path))
			Abort "The name already exists. Please select another name."
		endif
		Duplicate $mask_path, $newmask_path
		Print "new mask saved"
	endif

End


Function/S R2D_MaskNameDialog()
	string newmaskname
	Prompt newmaskname, "Enter new mask name: "		// Set prompt for x param
	DoPrompt "Enter new mask name", newmaskname
	if (V_Flag)
		return ""						// User canceled
	endif
	return newmaskname
End


/// Delete mask
Function R2D_DeleteMask()
	/// Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and imagelist.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	// get mask list and status list
	wave/T Z_MaskList = :Red2DPackage:Z_MaskList
	wave Z_MaskStatus = :Red2DPackage:Z_MaskStatus
	variable mask_num = DimSize(Z_MaskList,0)
	
	// if any masks are selected, alert user, if no mask selected, abort
	variable i
	variable count = 0
	string mask_path
	For(i=0; I<mask_num; i++)
		if(Z_MaskStatus[i][0] == 2^5+2^4)	// if check box is checked
			count ++
		endif
	Endfor
	if(count == 0)	// no mask is selected
		Abort "No mask is selected"
	else
		DoAlert 1, "Are you sure to delete the selected masks?"
		If(V_flag == 2)	// user canceled
			print "user canceled"
			return 0
		else	// user decided to delete
			For(i=0; I<mask_num; i++)
				if(Z_MaskStatus[i][0] == 2^5+2^4)	// if check box is checked
					mask_path = ":Red2DPackage:Mask:"+Z_MaskList[i][1]
					wave mask_wave = $mask_path
					R2D_RemoveMaskFromImage(mask_wave)
					KillWaves mask_wave
			endif
			Endfor
		Endif
	endif

End


/// Merge mask
Function R2D_MergeMasks()
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif

	// get mask list and status list
	wave/T Z_MaskList = :Red2DPackage:Z_MaskList
	wave Z_MaskStatus = :Red2DPackage:Z_MaskStatus
	variable mask_num = DimSize(Z_MaskList,0)	

	// if no mask selected, abort
	variable i
	variable count = 0
	string mask_path
//	string maskpath_list = ""
	For(i=0; I<mask_num; i++)
		if(Z_MaskStatus[i][0] == 2^5+2^4)	// if check box is checked
			count ++
		endif
	Endfor
	if(count == 0)	// no mask is selected
		Abort "No mask is selected"
	else	// if user decided to merge mask
		string newmask_name = R2D_MaskNameDialog()
		if(strlen(newmask_name) == 0)
				return -1	// user canceled
		endif
		string newmask_path = ":Red2DPackage:Mask:" + newmask_name
		string refmaskpath = ":Red2DPackage:Mask:"+Z_MaskList[0][1]
		Duplicate/O $refmaskpath, $newmask_path
		wave merged_mask = $newmask_path
		merged_mask = 0
		For(i=0; I<mask_num; i++)
			if(Z_MaskStatus[i][0] == 2^5+2^4)	// if check box is checked
				mask_path = ":Red2DPackage:Mask:"+Z_MaskList[i][1]
				wave targetwave = $mask_path
				MatrixOP/O merged_mask = merged_mask + targetwave
			endif
		Endfor
		Multithread merged_mask = merged_mask == 0 ? 0 : 1	// make all values other than zero becomes one.
	endif

End

// Rename mask
Function R2D_renameMask()
	/// Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and imagelist.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	// get mask list and status list
	wave/T Z_MaskList = :Red2DPackage:Z_MaskList
	wave Z_MaskStatus = :Red2DPackage:Z_MaskStatus
	variable mask_num = DimSize(Z_MaskList,0)
	
	// if a mask is selected, prompt a dialog to rename the mask, if no mask selected, abort
	variable i
	variable count = 0
	variable selectedindex
	string mask_path
	string newmask_name
	string newmask_path
	For(i=0; I<mask_num; i++)
		if(Z_MaskStatus[i][0] == 2^5+2^4)	// if check box is checked
			selectedindex = i
			count ++
		endif
	Endfor
	if(count == 0)	// no mask is selected
		Abort "No mask is selected"
	elseif(count > 1)	// more than one masks is selected
		Abort "More than one masks are selected. Please select one mask a time."
	elseif(count == 1)
		mask_path = ":Red2DPackage:Mask:"+Z_MaskList[selectedindex][1]
		newmask_name = R2D_MaskNameDialog()
		newmask_path = ":Red2DPackage:Mask:" + newmask_name
		if(strlen(newmask_name) == 0)
			Print "User canceled"
			return -1	// user canceled
		endif
		if(WaveExists($newmask_path))
			Abort "The name already exists. Please select another name."
		endif
		Rename $mask_path, $newmask_name
		Print "mask renamed"
	endif

End






/// Listbox
// Get Mast List in current datafolder and update maskList wave and its status wave.
Function/S R2D_GetMaskList(matchStr)
	string matchStr		// not in use 2024-06-03
	
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif

	// Get the mask list
	NewDataFolder/O :Red2DPackage:Mask
	string masklist = WaveList("*", ";", "DIMS:2,TEXT:0", :Red2DPackage:Mask)
	variable mask_num = itemsInList(masklist)
	wave/T maskname_wave = ListToTextWave(masklist, ";")
	
	// Create a listwave for mask
	Make/O/T/N=(mask_num,2) :Red2DPackage:Z_MaskList = ""
	wave/T Z_MaskList = :Red2DPackage:Z_MaskList
	SetDimLabel 1, 0, cb, Z_MaskList
	SetDimLabel 1, 1, MaskName, Z_MaskList
	if(mask_num == 0)	// this if pattern is used to prevent a bug of Igor Pro 9.0
	else
		Z_MaskList[][1] = maskname_wave[p]
	endif

	// Get a list of mask on graph
	string image_namelist = SortList(ImageNameList("IntensityImage",";"),";",1)	// get all image names from the specified graph
	variable image_number = itemsInList(Image_namelist)
	string dfr_name
	string image_name
	string maskongraph_list = ""	// initialize
	variable i
	for(i=0; i<image_number; i++)	// get all wave stored in red2dpackage:mask:
		image_name = StringFromList(i, image_namelist)
		wave image_wave = ImageNameToWaveRef("IntensityImage", image_name)	// set reference for image wave on graph
		dfr_name = GetWavesDataFolder(image_wave,1)	// get full path of the wave, no wave name
		if(StringMatch(dfr_name, "*:Red2DPackage:Mask:"))
			maskongraph_list += NameOfWave(image_wave) + ";"
		endif
	endfor	
	
	// Create a status wave for listwave.	The dimensionality of the selwave (status wave ) must be the same with listwave (z_masklist).
	Make/O/N=(mask_num,2) :Red2DPackage:Z_MaskStatus = 0	// the third dimension used for color
	wave Z_MaskStatus = :Red2DPackage:Z_MaskStatus
	string test_str
	for(i=0; i<mask_num; i++)
		test_str = StringFromList(i, masklist)
		if(WhichListItem(test_str, maskongraph_list) >= 0)	// if the selected mask in the maskongraph_list
			Z_MaskStatus[i][0] = 2^5+2^4	 //"bit" to control and check checkbox in listbox. bit5 means checkbox effective, 4 means checked.
		else
			Z_MaskStatus[i][0] = 2^5	 //"bit" to control and check checkbox in listbox. bit5 means checkbox effective, 4 means checked.
		endif
	endfor
	
	return maskongraph_list

End


Function ListControl_SelectMask(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	String userdata = lba.userdata
	
	If(row+1 > DimSize(listWave,0) || row < 0)  // prevent out of index error when user selects a row out of the list
		return -1
	Endif

	If(R2D_Error_ImagesExist(NoMessage = 1) == -1) // Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and imagelist.
		Abort
	Endif
	
	DoWindow IntensityImage
	If(V_flag == 0)
		return -1
	Endif

	string mask_name = listWave[row][1]	// get mask wave name
	string mask_path = ":Red2DPackage:Mask:"+mask_name	// get mask path
	wave mask_wave = $mask_path	// make a reference to the mask wave
	
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
			Switch(selWave[row][0])
				Case 32:
					R2D_AppendMaskToImage(mask_wave)
					selWave[row][0] += 2^4 //Add bit 4 to mark checkbox
					break
				Case 48:
					R2D_RemoveMaskFromImage(mask_wave)
					selWave[row][0] -= 2^4 //Remove bit 4 to unmark checkbox
					break
			Endswitch
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
					R2D_RemoveMaskFromImage(mask_wave)
					break
				Case 48:
					R2D_AppendMaskToImage(mask_wave)
					break
			Endswitch
			break
	endswitch

	return 0
End

Function R2D_AppendMaskToImage(mask_wave)
	wave mask_wave
	
	/// Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and imagelist.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	DoWindow IntensityImage
	if(V_flag == 0)
		return 0 // no IntensityImage
	endif
	
	string image_namelist
	
	/// append selected mask
	AppendImage/T/W=IntensityImage mask_wave	// append mask
	image_namelist = ImageNameList("IntensityImage",";")	// get image list on the graph
	variable image_num = itemsInList(image_namelist)	// get the image number on the graph
	string TraceNameOfCurrentMask = stringfromlist(image_num-1,image_namelist)	// get the "trace name" of appended mask; it should be the last item on the list
	ModifyImage/Z $TraceNameOfCurrentMask explicit=1, eval={0,0,0,0,0}, eval={1,60000,60000,60000,50000}	// make mask semitransparent
	
End

Function R2D_RemoveMaskFromImage(mask_wave)
	wave mask_wave

	/// Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and imagelist.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	DoWindow IntensityImage
	if(V_flag == 0)
		return 0 // no IntensityImage
	endif

	/// Remove all instance of the selected mask wave
	string image_namelist = SortList(ImageNameList("IntensityImage",";"),";",1)	// get all image names from the specified graph
	variable image_number = itemsInList(Image_namelist)	// get image number
	string dfr_name
	string image_name
	variable i
	for(i=0; i<image_number; i++)	// check if the image wave is stored in Red2DPackage:Mask:
		image_name = StringFromList(i, image_namelist)
		wave image_wave = ImageNameToWaveRef("IntensityImage", image_name)	// set reference for image wave on graph
		dfr_name = GetWavesDataFolder(image_wave,1)	// get full path of the wave, no wave name
		if(StringMatch(dfr_name, "*:Red2DPackage:Mask:"))	// check if the image is a mask
			if(cmpstr(NameOfWave(image_wave), NameOfWave(mask_wave)) == 0)	// check if the mask is equal to the specified mask
				RemoveImage/Z/W=IntensityImage $image_name	// use nameOfwave instead of name of traces to remove all image instance of the same wave
			endif
		endif
	endfor	

End


//Make masked images
Function R2D_MakeMaskedImages()

	/// Check if in the image folder. Do not delete this because you need to be in image folder.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif

	string masklist = R2D_GetMaskList_simple()	// get mask list (function stored in CircularAverage.ipf)
	string selected_mask = R2D_SelectMaskDialog(masklist)	// let user select a mask (function stored in CircularAverage.ipf)
	if(strlen(selected_mask) == 0)
		print "User canceled."
		return	0
	elseif(StringMatch(selected_mask, "No Mask"))
//		print "User selected no mask."
		return	0
	endif
	string mask_path = ":Red2DPackage:Mask:" + selected_mask
	wave mask = $mask_path
	
	/// Crate a new folder to save original images
	String ImageFolderName = "OriginalImages"
	variable i
	For(i = 0; i < 100; i++)
		If(DataFolderExists(ImageFolderName) == 0)
			break
		Else
			ImageFolderName = "OriginalImages_" + num2str(i+1)
		Endif
	Endfor
	NewDataFolder $ImageFolderName
	
	/// Get Imagelist
	Wave/T ImageList = :Red2Dpackage:ImageList
	Variable numOfImages = Dimsize(ImageList,0)

	/// Backup original images and make masked images
	string backup_wave_path
	For(i=0;i<numOfImages;i+=1)
		String SelImageName = ImageList[i]
		Wave/Z SelImage = $SelImageName
		If(waveExists(SelImage))
			backup_wave_path = ":" + ImageFolderName + ":" + SelImageName
			Duplicate/O SelImage, $backup_wave_path	// backup original images			
			Multithread SelImage = mask == 1 ? NaN : SelImage[p][q]	// Make masked images
		Endif
	Endfor
	
	Print "Mask applied"
	
End





