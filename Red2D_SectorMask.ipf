#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


/////////GUI//////////

Function Red2D_SectorMaskPanel(refresh)
	variable refresh
	/// Check if in images folder by checking if there is an imagelist in the package folder.
	If(Red2Dimagelistexist() == -1)
		return -1
	Endif	

	/// Set global variables, which are shared with the other procedures. 
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
		Variable/G U_phi0, U_dphi, U_X0, U_Y0
	SetdataFolder saveDFR

	/// Create a new panel to collect parameter to perform circular average
	If(refresh == 0)
		NewPanel/K=1/N=SectorMask/W=(200,200,420,500)
	Endif
	SetVariable setvar0 title="X0 [pt]",pos={10,10},size={200,25},limits={-inf,+inf,1},fSize=13, value=U_X0
	SetVariable setvar1 title="Y0 [pt]",pos={10,35},size={200,25},limits={-inf,+inf,1},fSize=13, value=U_Y0
	SetVariable setvar2 title="phi0 [º]",pos={10,60},size={200,25},limits={0,180,1},fSize=13, value=U_phi0, help={"phi0 should be in range of 0 - 180."}
	SetVariable setvar3 title="dphi [º]",pos={10,85},size={200,25},limits={0,180,1},fSize=13, value=U_dphi, help={"dphi should be in range of 0 - 180."}
	Button button0 title="Create Sector Mask",size={160,25},pos={30,125},proc=ButtonProcCreSectorMask
	Button button1 title="Apply Mask Top Image",size={160,25},pos={30,165},proc=ButtonProcApplySectorMaskToTop
	Button button2 title="Apply Mask All Image",size={160,25},pos={30,205},proc=ButtonProcApplySectorMaskToAll
	Button button3 title="Refresh",size={160,25},pos={30,245},proc=ButtonProcRefreshSecMask
	
End

Function ButtonProcCreSectorMask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			CreSectorMask()
		 
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProcRefreshSecMask(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			Red2D_SectorMaskPanel(1)
		 
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProcApplySectorMaskToTop(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			ApplySectorMaskToAllImages(0)
				 
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProcApplySectorMaskToAll(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up

			ApplySectorMaskToAllImages(1)
			
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End


/////////Main Code///////////

/// Create Sector Mask
Static Function CreSectorMask()
	//Check if in images folder by checking if there is an imagelist in the package folder.
	If(Red2Dimagelistexist() == -1)
		return -1
	Endif	
			
	//Get Top Image
	String ImageList = ImageNameList("",";")
	String TopImageName = StringFromList(0, ImageList,";")
	Wave TopImage = $(TopImageName)
				
	//Set global variables, which are shared with the other procedures. 
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
	Variable/G U_Xmax, U_Ymax, U_X0, U_Y0, U_phi0, U_dphi
			
	//Calcualte Xmax and Ymax again in case.
	U_Xmax=Dimsize(TopImage,0)-1
	U_Ymax=Dimsize(TopImage,1)-1
	
	//Duplicate Top Image as SectorMask and save it in package folder.
	Duplicate/O TopImage, SectorMask, phiMap_sector
			
	Multithread SectorMask = 1 //type 1 for the process below.
	//0 denotes the pixels to be masked.
	//1 denotes the pixels to be used.
			
	//Create SectorMask
	variable i, j
	variable/C z
	variable phi
	For(i=0; i<U_Xmax+1; i+=1) //gXmax is the coordinates.
		For(j=0; j<U_Ymax+1; j+=1)
			/// Get the polar cordinate of the selected pixcel.
			z = r2polar(cmplx(i-U_X0,-j+U_Y0))
			phi = imag(z)/pi*180
	    			
			/// Change 0->+180, 0->-180 style to 0->+360 sytle
	   		If(phi<0)
	   			phi +=360
	   		Endif
    				
   	 		/// Type 1 into SectorMask when phi in range.
    		If(U_phi0 - U_dphi/2 < 0 && phi >= U_phi0 - U_dphi/2 + 360)
    			SectorMask[i][j] = 0
    		Elseif(U_phi0 - U_dphi/2 <= phi && phi <= U_phi0 + U_dphi/2)
	   			SectorMask[i][j] = 0
	   		Elseif(U_phi0 + 180 - U_dphi/2 <= phi && phi <= U_phi0 + 180 + U_dphi/2)
	   			SectorMask[i][j] = 0
	   		Elseif(U_phi0 + 180 + U_dphi/2 >= 360 && phi + 360 <= U_phi0 + 180 + U_dphi/2)
	   			SectorMask[i][j] = 0
   			Endif
   			
		Endfor
	Endfor
		 
	//Append M_SectorMask to Top Image
	RemoveImage/Z SectorMask //ImageName is the actual Image Name, not the wave name
	AppendImage/T SectorMask //When appending it should be wave name
	ModifyImage SectorMask explicit=1, eval={1,0,0,0,0}, eval={0,60000,60000,60000,50000} // eval is color. (eval={value, red, green, blue [, alpha]})

	SetDataFolder saveDFR
	
End

/// Apply mask
Static Function ApplySectorMaskToAllImages(type)
	variable type
	
	/// Check if in image folder
	If(Red2Dimagelistexist() == -1)
		return -1
	Endif
	
	/// Store home position
	DFREF homeDFR = GetDataFolderDFR()
	
	/// Get mask
	Wave SectorMask = :Red2Dpackage:Sectormask
	
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
		masked2D = TopImage*SectorMask + SectorMask - 1
		
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
			masked2D = SelImage*SectorMask + SectorMask - 1
			
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