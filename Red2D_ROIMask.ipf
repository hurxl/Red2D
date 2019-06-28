#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

////////GUI////////

Function Red2D_ROIMaskPanel(refresh)
	variable refresh
	
	//Check if in images folder by checking if there is an imagelist in the package folder.
	If(Red2Dimagelistexist() == -1)
		return -1
	Endif	

	//Create a new panel to collect parameter to perform circular average
	If(refresh == 0)
		NewPanel/K=1/N=ROIMask/W=(200,200,430,440)
	Endif
	DrawText 20, 30, "Draw ROI using Igor default feature."
	DrawText 20, 50, "Image -> Image ROI..."
	Button button0 title="Convert ROI to Mask",size={140,25},pos={50,70},proc=ButtonProcCreROIMask
	Button button1 title="Apply ROI Mask Top",size={140,25},pos={50,110},proc=ButtonProcApplyROIMaskToTop
	Button button2 title="Apply ROI Mask All",size={140,25},pos={50,150},proc=ButtonProcApplyROIMaskToAll
	Button button3 title="Refresh",size={140,25},pos={50,190},proc=ButtonProcRefreshROIMask
End

Function ButtonProcCreROIMask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			ConvertROI2Mask()
	 		
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProcRefreshROIMask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			Red2D_ROIMaskPanel(1)
		 
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProcApplyROIMaskToTop(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
		
			ApplyROIMaskToAllImages(0) // 0 denotes top image only
	 		
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProcApplyROIMaskToAll(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
		
			ApplyROIMaskToAllImages(1) // 1 dentoes all images
	 		
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End


//////////Main Code////////////
/// Create Mask
Static Function ConvertROI2Mask()

	If(Red2Dimagelistexist() == -1)
		return -1
	Endif	
	
	///////////////Convert ROI to mask/////////////////
	String TopImage = StringFromList(0, ImageNameList("",";"),";")
	ImageGenerateROIMask $TopImage // Convert ROI to mask (1 for ROI and 0 for the others)
	Wave refmask = M_ROIMask // ROI mask is stored in a wave "ROIMask"
	
	DFREF saveDFR = GetDataFolderDFR()
	SetdataFolder Red2Dpackage
	
	Duplicate/O refmask, ROIMask
	ROIMask = 1 - ROIMask

	//Append M_SectorMask to Top Image
	RemoveImage/Z ROIMask //ImageName is the actual Image Name, not the wave name
	AppendImage/T ROIMask //When appending it should be wave name
	ModifyImage ROIMask explicit=1, eval={1,0,0,0,0}, eval={0,60000,60000,60000,50000} // eval is color. (eval={value, red, green, blue [, alpha]})
	
	SetdataFolder saveDFR
	
	Killwaves refmask
	
End

/// Apply Mask
Static Function ApplyROIMaskToAllImages(type)
	variable type
	
	/// Check if in image folder
	If(Red2Dimagelistexist() == -1)
		return -1
	Endif
	
	/// Store home position
	DFREF homeDFR = GetDataFolderDFR()
	
	/// Get mask
	Wave ROIMask = :Red2Dpackage:ROImask
	
	/// Create a new Masked Images folder
	If(DataFolderExists("MaskedImages") == 0)
		NewDataFolder MaskedImages
	Endif
	
	/// @home folder
	/// Check single process or all process
	If(type == 0) // single process
		/// Get topimage
		String TopImageName = ImageNameList("",";")
		TopImageName = StringFromList(0, TopImageName,";")
		TopImageName = ReplaceString("'", TopImageName, "") //delete 'name' from the name. Otherwise sometimes igor does not function.
		Wave TopImage = $TopImageName
		
		/// Apply mask
		Duplicate/FREE/O TopImage, masked2D // masked2D is a temporary wave
		masked2D = TopImage*ROIMask + ROIMask - 1
		
		/// Duplicate Masked Image into Masked image folder
		SetDataFolder MaskedImages // move to masked image folder
		Duplicate/O masked2D, $TopImageName
		SetDataFolder homeDFR
	Elseif(type == 1) // all process
		/// Get Imagelist
		Wave/T ImageList = :Red2Dpackage:ImageList
		Variable numOfImages = Dimsize(ImageList,0)
		
		Variable i
		For(i=0;i<numOfImages;i+=1)
			/// Apply mask to all images
			String SelImageName = ImageList[i]
			Wave SelImage = $(SelImageName)
			Duplicate/FREE/O SelImage, masked2D // masked2D is a temporary wave
			masked2D = SelImage*ROIMask + ROIMask - 1
			
			/// Duplicate Masked Image into Masked image folder
			SetDataFolder MaskedImages // move to masked image folder
			Duplicate/O masked2D, $SelImageName
			SetDataFolder homeDFR //move back to home folder to get new image
		Endfor
	Endif
	
	/// @home folder
	/// need to transfer these variables to the newly made folder
	NVAR Xmax = :Red2Dpackage:U_Xmax
	NVAR Ymax = :Red2Dpackage:U_Ymax
	NVAR X0 = :Red2Dpackage:U_X0
	NVAR Y0 = :Red2Dpackage:U_Y0
	NVAR phi0 = :Red2Dpackage:U_phi0
	NVAR dphi = :Red2Dpackage:U_dphi
	NVAR pixelsize = :Red2Dpackage:U_pixelsize
	NVAR SDD = :Red2Dpackage:U_SDD
	NVAR Lambda = :Red2Dpackage:U_Lambda
	NVAR tiltX = :Red2Dpackage:U_tiltX
	NVAR tiltY = :Red2Dpackage:U_tiltY
	NVAR tiltZ = :Red2Dpackage:U_tiltZ
	
	/// Copy the above global variables to :MaskedImages:Red2Dpackage
	SetDataFolder MaskedImages
	If(DataFolderExists("Red2Dpackage") == 0)
		NewDataFolder Red2Dpackage
	Endif
	SetDataFolder Red2Dpackage
	Variable/G U_Xmax, U_Ymax, U_X0, U_Y0, U_phi0, U_dphi, U_pixelsize, U_SDD, U_tiltX, U_tiltY, U_tiltZ, U_Lambda
	U_Xmax = Xmax
	U_Ymax = Ymax
	U_X0 = X0
	U_Y0 = Y0
	U_phi0 = phi0
	U_dphi = dphi
	U_pixelsize = pixelsize
	U_SDD = SDD
	U_tiltX = tiltX
	U_tiltY = tiltY
	U_tiltZ = tiltZ
	U_Lambda = Lambda
	
	/// @home folder
	SetdataFolder homeDFR

End