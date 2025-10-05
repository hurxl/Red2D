#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// *** Misc

// CUI Only 2024-11-10
Function R2D_FindHotPixels(threshold)
	variable threshold

	// get top image except masks
	string image_namelist = ImageNameList("IntensityImage",";")
	string topimage_name = StringFromList(0, image_namelist)
	wave/Z TopImage = $topimage_name
	
	Duplicate/O TopImage, Hotpixels
	Multithread Hotpixels = TopImage[p][q] > threshold ? 1 : 0
	MatrixOP/O/FREE hotsum = sum(Hotpixels)
	printf "%g hot pixels found\r", hotsum[0]
	make/O/N=(hotsum[0],2) hotpixel_loc

	MatrixOP/O/FREE sumrowarray = sumrows(Hotpixels)
	
	variable xsize = DimSize(Hotpixels, 0)
	variable ysize = DimSize(Hotpixels, 1)
	
	variable i, j
	variable count = 0
	for(i=0; i<xsize; i++)
		if(sumrowarray[i] > 0)	// if this column contains more than one hot pixel
			MatrixOP/O/FREE targetrow = row(Hotpixels, i)
			for(j=0; j<ysize; j++)
				if(targetrow[j] > 0)
					hotpixel_loc[count][0] = i
					hotpixel_loc[count][1] = j
					count ++
				endif
			endfor
		endif
	endfor

End

// This function makes the panel space (NaN) black. NaN shows white color.
Function R2D_NaN2en30()
	
	R2D_CreateImageList(1)  // create a imagelist of current datafolder, sort by name. 1 for name, 2 for date_created.
	Wave/T ImageList = :Red2DPackage:ImageList
	Variable numOfImages = DimSize(ImageList,0)
	
	variable i
	For(i = 0; i < numOfImages; i++)
		wave refwave = $ImageList[i]
		Redimension/S refwave  // change 32bit signed integer to signed single float
		Multithread refwave[][] = numtype(refwave[p][q]) == 2 ? 1e-30 : refwave[p][q]
	Endfor
	
End

Function R2D_negative2zero()
	
	R2D_CreateImageList(1)  // create a imagelist of current datafolder, sort by name. 1 for name, 2 for date_created.
	Wave/T ImageList = :Red2DPackage:ImageList
	Variable numOfImages = DimSize(ImageList,0)
	
	variable i
	For(i = 0; i < numOfImages; i++)
		wave refwave = $ImageList[i]
		Redimension/S refwave  // change 32bit signed integer to signed single float
		Multithread refwave[][] = refwave[p][q] < 0 ? 0 : refwave[p][q]	
	Endfor
	
	Print "Success. Images in current datafolder were converted to datatype single float. Pixels with -1 was replaced with NaN."
	
End

Function R2D_negative2NaN()
	
	R2D_CreateImageList(1)  // create a imagelist of current datafolder, sort by name. 1 for name, 2 for date_created.
	Wave/T ImageList = :Red2DPackage:ImageList
	Variable numOfImages = DimSize(ImageList,0)
	
	variable i
	For(i = 0; i < numOfImages; i++)
		wave refwave = $ImageList[i]
		Redimension/S refwave  // change 32bit signed integer to signed single float
		Multithread refwave[][] = refwave[p][q] < 0 ? NaN : refwave[p][q]	
	Endfor
	
	Print "Success. Images in current datafolder were converted to datatype single float. Pixels with -1 was replaced with NaN."
	
End


Function R2D_Sensitivity2D()
	/// Check if in the image folder.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	/// create a image list by the name order.
	/// Current R2D_CreateImageList will create a list of all 2D waves. But I need to remove the _s waves for this update.
	R2D_CreateImageList(1)
	Wave/T ImageList = :Red2DPackage:ImageList
	Variable numOfImages = DimSize(ImageList,0)
	
	If(numOfImages == 0)
		Print "No image exist."
		return -1
	Endif
	

	Killwindow/Z SensitivityCorrectionPanel2D
	NewPanel/K=1/W=(100,100,550,300) as "Sensitivity correction"
	RenameWindow $S_name, SensitivityCorrectionPanel2D
	
	TitleBox WSPopupTitle2,pos={70,20}, frame=0, fSize=14, title="\\JCSelect a reference image \rto create a correction file for detector sensitivity"
	Button SenseImage_Selector,pos={25,60},size={400,23}, fSize=14
	MakeButtonIntoWSPopupButton("SensitivityCorrectionPanel2D", "SenseImage_Selector", "MakeSenseWavePopupWaveSelectorNotify", popupWidth = 400, popupHeight = 600, options=PopupWS_OptionFloat)
	PopupWS_MatchOptions("SensitivityCorrectionPanel2D", "SenseImage_Selector", matchStr = "*", listoptions = "DIMS:2,TEXT:0")
	PopupWS_SetPopupFont("SensitivityCorrectionPanel2D", "SenseImage_Selector", fontsize = 13)
	Button bt1,pos={100,105},size={250,23}, fSize=14, proc=R2D_MakeSensitivityButtonProc2D,title="Make a correction file"
	Button bt0,pos={140,150},size={170,23}, fSize=14, proc=R2D_CorrectSensitivityButtonProc2D,title="Start correction"

End

Function R2D_CorrectSensitivityButtonProc2D(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			/// Get the sensitivity wave
			wave/Z sensitivity = :Red2Dpackage:sensitivity
			If(!WaveExists(sensitivity))  // if sensitivity file does not exist
				Abort "Sensitivity wave does not exist. You need to make a sensitivity wave first."
			Endif

			/// Get imagelist
			Wave/T ImageList = :Red2DPackage:ImageList
			Variable numOfImages = DimSize(ImageList,0)
			
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
	
			// Duplicate the images to the OriginalImages folder
			variable j
			For(j = 0; j < numOfImages; j++)
				wave refwave = $ImageList[j]
				string newname = ":" + ImageFolderName + ":" + NameOfWave(refwave)
				Duplicate/O refwave $newname
			Endfor
//			String PackageFolderPath = ":" + ImageFolderName + ":Red2DPackage"
//			DuplicateDataFolder/O=1 Red2DPackage $PackageFolderPath
//			SetDataFolder $ImageFolderName

			///////////////////////////Correct sensitivity////////////////////////////////
			For(i=0;i<numOfImages; i+=1)
				//Set reference of target wave in current folder. Only deal with waves having name in refname(Datasheet).
				Wave target = $ImageList[i]

				// correct sensitivity
				target /= sensitivity
				
			Endfor
	
			Killwindow SensitivityCorrectionPanel2D
			Print ImageList
			Print "were divided with the sensitivity file"
					
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function R2D_MakeSensitivityButtonProc2D(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			
			// GET the selected reference WAVE
			String SensitivityPath = PopupWS_GetSelectionFullPath("SensitivityCorrectionPanel2D", "SenseImage_Selector")
			If(cmpstr(SensitivityPath, "(no selection)", 0) == 0)
				Print "False"
				Abort "No selection."
			Endif
			
			// Check if solid angle map exists
			Wave/Z SolidAngleMap = :Red2DPackage:SolidAngleMap // get the solidangle wave created by above function.
			If(!WaveExists(SolidAngleMap))
				Print "False"
				Abort "The wave SolidAngleMap does not exist. Please run either Fit Standard or Circular Average to generate this wave in the background."
			Endif
			
			// Create a refcell in the new folder with the selected cell path
			// The sensitivity standards, e.g., H2O and lupolen, should not have a constant intensity on the 2D images.
			// There should be a natural decrease in the intensity as the pixels going out from the beam center
			// because of the decrease of solid angle per pixel.
			// Therefore, when creating the pixel sensitivity file, I should remove the natural decrease from the file.
			Duplicate/O $SensitivityPath, :Red2Dpackage:sensitivity
			Wave Sensitivity = :Red2Dpackage:sensitivity
			Multithread Sensitivity[][] = Sensitivity[p][q] == 0 ? NaN : Sensitivity[p][q]  // convert zero value to NaN to remove these pixels from calculation.
			R2D_calc_qMap() // calculate solidangle correction map. the function locates in the circular average ipf.
			
			MatrixOP/O Sensitivity = Sensitivity/SolidAngleMap
//			MatrixOP/O Sensitivity = Sensitivity
			ImageStats Sensitivity
			Sensitivity /= V_avg
			Print "A sensitivity correction file was created and stored in Red2Dpackage datafolder."

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// *************************
// *** Simple Circular Average
// Simply take a circular avegae of the images. No q vector conversion and no solid angle corrections.
// *************************
/////////GUI/////////

Function R2D_CircularAveragePanel_simple()
	
	/// Check if in the image folder. Error_ImgaesExist will create a Red2Dpackage folder.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	/// Check if Red2DPackage folder exists
	If(DataFolderExists("Red2DPackage") == 0)	// if folder does not exist
		NewDataFolder Red2DPackage
	Endif
	
	String reflist = wavelist("*",";","DIMS:2,TEXT:0") //Get wavelist from current folder limited for 2D waves
	Wave/T reftw = ListToTextWave(reflist,";") // Create a text wave reference containing reflist
	Wave TopImage = $reftw[0]
	
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
		Variable/G U_Xmax, U_Ymax, U_X0, U_Y0, U_PixelSize, U_SortOrder// U_tiltZ is not in use. It is actuall X2. I use X-Y-X type rotation.
		String/G U_MaskName_All_CA, U_MaskName_Auto
		Variable/G U_row_CA
		U_Xmax=Dimsize(TopImage,0)-1 //Get image size. Minus 1 because Dimsize is size while Xmax means the coordinates.
		U_Ymax=Dimsize(TopImage,1)-1 //Get image size
		NVAR SortOrder = U_SortOrder

		If(numtype(U_X0) != 0)
			U_X0 = 0
		Endif
		If(numtype(U_X0) != 0)
			U_Y0 = 0
		Endif
		If(U_PixelSize == 0 || numtype(U_PixelSize) != 0)
			U_PixelSize = 1
		Endif
		If(U_SortOrder == 0 || numtype(U_SortOrder) != 0)
			U_SortOrder = 1
		Endif
		If(numtype(U_row_CA) != 0)
			U_row_CA = 0
		Endif

	SetdataFolder saveDFR

	/// Check if panel exist
	DoWindow SimpleCircularAverage
	If(V_flag == 0)
		NewPanel/K=1/N=SimpleCircularAverage/W=(200,200,900,550)
	Else
		DoWindow/F SimpleCircularAverage
	Endif
	
	SetVariable setvar0 title="X0 [pt]",pos={10,30},size={200,25},limits={-inf,inf,1},fSize=13, value=:Red2DPackage:U_X0
	SetVariable setvar1 title="Y0 [pt]",pos={10,60},size={200,25},limits={-inf,inf,1},fSize=13, value=:Red2DPackage:U_Y0
	SetVariable setvar2 title="Pixel Size [n.a.]",pos={10,90},size={200,25},limits={0,inf,1},fSize=13, value=:Red2DPackage:U_PixelSize

	Button button0 title="Circular Average",size={130,23},pos={45,200}, proc=ButtonProcCA_simple
	Button button1 title="Refresh",size={100,22},pos={60,300}, proc=ButtonProcRefreshListCA_simple

	
	// Create a popupmenu to select the order of ImageList and then create the Imagelist
//	string ord = "Date Created"
//	PopupMenu popup0 title="Sort list by ",value="Name;Date Created",fSize=12, pos={220,272}, mode=SortOrder, proc=PopMenuProc_CA_SortOrder_simple
//	R2D_CreateImageList(SortOrder)  // 1 for name, 2 for date created
//	ListBox lb listWave=:Red2DPackage:ImageList, mode=0, frame=0, pos={220,5}, size={350,260}, fSize=13	

	R2D_GetImageList_CA("")
	ListBox lb listWave=:Red2DPackage:Z_ImageList_CA
	ListBox lb mode=2, frame=0, pos={240,5}, size={450,330}, fSize=13, widths={150,100}, userColumnResize=1, proc=ListControl_SelectMask_CA

	PopupMenu popup1 title="Set all mask", pos={15,120}, fSize=13, value=R2D_GetMaskList_simple(), proc=Update_MaskName_All_CA
	Execute/P/Q "PopupMenu popup1 pos={15,120}"  // a workaround about Igor's know bug for bodywidth option.
	
End

Function ButtonProcRefreshListCA_simple(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			R2D_CircularAveragePanel_simple() // when refresh is specified, no matter what value, it goes to the true case.
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function PopMenuProc_CA_SortOrder_simple(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			NVAR SortOrder = :Red2DPackage:U_SortOrder
			SortOrder = popNum
			R2D_CreateImageList(SortOrder)  // 1 for name, 2 for date created
			ListBox lb listWave=:Red2DPackage:ImageList
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function ButtonProcCA_simple(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			DoCircularAverage_simple()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


/////////Main Code/////////
/// Perform circular average
Function DoCircularAverage_simple()

	/// Check if in the image folder.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	DoWindow/H
	Print "In preparation for circular averaging ..."
	Doupdate

	/// Create a new folder to store the generated 1D data.
	variable i
	string dfname
	
	dfname = UniqueName("Ip1D",11,0)
	NewDataFolder $dfname
	string df1d = GetDataFolder(1, $dfname)
			
	/// Get global variables for the following procedures.
	Wave/T ImageList = :Red2DPackage:ImageList
	Variable numOfImages = DimSize(ImageList,0)
	Wave TopImage = $ImageList[0]
						
	NVAR U_Xmax = :Red2DPackage:U_Xmax
	NVAR U_Ymax = :Red2DPackage:U_Ymax
	NVAR U_Lambda = :Red2DPackage:U_Lambda
	U_Xmax = Dimsize(TopImage,0) - 1		// These global variables are used in clac_q and circular average.
   U_Ymax = Dimsize(TopImage,1) - 1
			
   /// Calculate q at each pixel, using the info in Red2Dpackage. Solid angle correction factor is generated as well.
   R2D_calc_pMap_simple()
   NVAR U_pres = :Red2DPackage:U_pres
	NVAR U_pmin = :Red2DPackage:U_pmin
	NVAR U_pnum = :Red2DPackage:U_pnum

  	/// Calculate 1D pp
   make/O/D/N=(U_pnum) :Red2DPackage:pp
	wave pp = :Red2DPackage:pp
	pp = U_pmin + U_pres*p
	DeletePoints U_pnum-5, 5, pp
	DeletePoints 0, 1, pp

	//////////////////Start circular average///////////////
	wave/T Z_ImageList_CA = :Red2DPackage:Z_ImageList_CA
	string mask_path
	For(i=0; i<numOfImages; i++)
	
		Variable t0=StartMsTimer // Start Timer
		mask_path = ":Red2DPackage:Mask:"+Z_ImageList_CA[i][1]
		CircularAverage_simple($(ImageList[i]), df1d, $mask_path) // Do circular average
		Print i+1,"/",numOfImages, ";", StopMSTimer(t0)/1E+6, "sec/image" //End Timer	
		
	Endfor

	SetDataFolder $dfname
	Print "Complete"
	
End

///// Calculate p_map
Function R2D_calc_pMap_simple()

	/// Check if in the image folder.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
		
	/// Move to package folder
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage

	Variable/G U_Xmax, U_Ymax, U_X0, U_Y0, U_SDD, U_PixelSize, U_pnum, U_pres, U_pmin
		
	/// Unit vector in roated plane
	Make/FREE/D/O/N=3 xvec, yvec, zvec, pvec, qvec
	xvec = {1,0,0} 
	yvec = {0,1,0}
	zvec = {0,0,1}
	
	Make/FREE/D/O/N=(U_Xmax+1,U_Ymax+1,3) pvecMap //contains px, py, pz at each layer.
	Make/D/O/N=(U_Xmax+1,U_Ymax+1) pindexMap

	Multithread pvecMap = (p-U_X0)*xvec[r]*U_PixelSize + (q-U_Y0)*yvec[r]*U_PixelSize + 0*zvec[r]
	MatrixOP/FREE/O pscalarMap = sqrt(pvecMap[][][0]*pvecMap[][][0] + pvecMap[][][1]*pvecMap[][][1] + pvecMap[][][2]*pvecMap[][][2])
	
	U_pres = U_PixelSize	// p resolution is set to pixel size of the p-map
	Multithread pindexMap = round(pscalarMap/U_pres)
	variable pindex_min = WaveMin(pindexMap)
	Multithread pindexMap -= pindex_min		// make index starts from zero
	U_pnum = WaveMax(pindexMap) + 1 //qindexMap starts from 0
	U_pmin = WaveMin(pscalarMap)
	
	/// Move back to image folder.
	SetdataFolder saveDFR
	
End

/// Circular average loop
ThreadSafe Static Function CircularAverage_simple(pWave, df1d, mask_wave)
	Wave pWave
	string df1d
	wave/Z mask_wave
	
	/// Set global variables, which are shared with the other procedures. 
	NVAR Xmax = :Red2DPackage:U_Xmax
	NVAR Ymax = :Red2DPackage:U_Ymax
	NVAR pnum = :Red2DPackage:U_pnum
	Wave pindexMap = :Red2DPackage:pindexMap	// the true p value of each pixel is digitized by a minimum p value.
	
	/// Setup for mask
	If(!WaveExists(mask_wave))	// if the selected wave does not exist or user did not select a mask wave
		Duplicate/FREE/O pindexMap, mask_wave	// manually make a mask wave
		mask_wave = 0	// 0 means no masking
//		Print "no mask"
	Endif

   /// Create a refwave to store values. added int and count number.
   make/FREE/D/O/N=(pnum) refint, intensity, count
	
  	/// Start circular average
   variable i, j, pindex
   count = 0 //initialize count
   
   /// Add pixels to get circular sum
   for(i=0; i<Xmax+1; i++) //gXmax is the coordinates.
    	for (j=0; j<Ymax+1; j++)

    		if(numtype(pWave[i][j]) == 2 || mask_wave[i][j] == 1)
    			//skip add when intensity is NaN.
    		else
    			//Get theta of the selected pixel.
    			pindex = pindexMap[i][j] //thetaMap[i][j] contains normalized theta values (Integer) by a minimum theta value deterimined above.
    			// ADD INTENSITY.
	 	  	 	refint[pindex] += pWave[i][j] // Add intensity per solid angle instead of per pixel.
	 	  	 	count[pindex] += 1 //calculate the pixel number that corresponds to distance r, considering the mask.
	 	   endif
	 	   
	 	endfor
	 endfor
	 
	/// Calcuate mean
	intensity = refint/count
	DeletePoints pnum-5, 5, intensity
	DeletePoints 0, 1, intensity
	
	string newIntName = df1d + NameofWave(pWave) + "_i"
	string newQName = df1d + NameofWave(pWave) + "_p"
	duplicate/O/D intensity $newintname
	duplicate/O/D :Red2DPackage:pp $newQName
	
End



// *************************
// *** Convert 2D
// *************************

/////////GUI/////////
Function R2D_2DImageConverterPanel()
	
	/// User may directly come to circular average. In that case, the Red2DPackage folder and ImageList does not exist.
	If(DatafolderExists("Red2DPackage")==0)
		NewDataFolder :Red2DPackage
	Endif

	String reflist = wavelist("*",";","DIMS:2,TEXT:0") //Get wavelist from current folder limited for 2D waves
	Wave/T reftw = ListToTextWave(reflist,";") // Create a text wave reference containing reflist
	Variable NumInList = itemsinlist(reflist) // Get number of items in List
	Wave TopImage = $reftw[0]

	Duplicate/T/O reftw, :Red2DPackage:ImageList
	
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
		Variable/G U_Xmax, U_Ymax, U_X0, U_Y0, U_SDD, U_Lambda, U_PixelSize, U_tiltX, U_tiltY, U_tiltZ, U_phiOffset // U_tiltZ is not in use. It is actuall X2. I use X-Y-X type rotation.
		U_Xmax=Dimsize(TopImage,0)-1 //Get image size. Minus 1 because Dimsize is size while Xmax means the coordinates.
		U_Ymax=Dimsize(TopImage,1)-1 //Get image size
		If(numtype(U_phiOffset) != 0)
			U_phiOffset = 0
		Endif
	SetdataFolder saveDFR
	
	/// Check if panel exist
	DoWindow Convert_2D_coordinates
	If(V_flag == 0)
		NewPanel/K=1/N=Convert_2D_coordinates/W=(800,100,1450,420)
	Else
		DoWindow/F Convert_2D_coordinates
	Endif
	
	SetVariable setvar0 title="X0 [pt]",pos={20,5},size={200,25},limits={-inf,inf,1},fSize=13, value=U_X0
	SetVariable setvar1 title="Y0 [pt]",pos={20,30},size={200,25},limits={-inf,inf,1},fSize=13, value=U_Y0
	SetVariable setvar2 title="SDD [m]",pos={20,55},size={200,25},limits={0,inf,0.1},fSize=13, value=U_SDD
	SetVariable setvar3 title="Tilt_X [º]",pos={20,80},size={200,25},limits={-90,90,1},fSize=13, value=U_tiltX, help={"-90 to 90º"}
	SetVariable setvar4 title="Tilt_Y [º]",pos={20,105},size={200,25},limits={-90,90,1},fSize=13, value=U_tiltY, help={"-90 to 90º"}
	SetVariable setvar5 title="Lambda [A]",pos={20,130},size={200,25},limits={0,inf,0.1},fSize=13, value=U_Lambda, help={"Cu = 1.5418A, Mo = 0.7107A"}
	SetVariable setvar6 title="Pixel Size [um]",pos={20,155},size={200,25},limits={0,inf,1},fSize=13, value=U_PixelSize, help={"Pilatus = 172um, Eiger = 75um, Rigaku = 100 um"}
	SetVariable setvar7 title="phi offset [º]",pos={20,180},size={200,25},limits={0,inf,1},fSize=13, value=U_phiOffset, help={"start angle offset"}
	ListBox lb listWave=:Red2DPackage:ImageList, frame=0, mode=0, pos={240,5}, size={400,300}, fSize=13
	Button button0 title="Convert to Azimuthal Images",size={200,23},pos={20,210},proc=ButtonProcAz2D
	Button button1 title="Convert to qx-qy Images",size={200,23},pos={20,240},proc=ButtonProcqxqy2D
	Button button2 title="Refresh",size={120,23},pos={60,280},proc=ButtonProcRefreshListAz2D
	
End

Function ButtonProcRefreshListAz2D(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			R2D_2DImageConverterPanel()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcAz2D(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NVAR phi_offset = :Red2DPackage:U_phiOffset
			Azimuthal2D(phi_offset)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcqxqy2D(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up

			R2D_QxQy2D()
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// *** Azimuthal Conversion
Static Function Azimuthal2D(phi_offset)
	variable phi_offset
	
	/// Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and a imagelist.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	/// Create a folder to save converted images
	NewDataFolder/O Azimuthal2D
	string dfAz2d = GetDataFolder(1, Azimuthal2D)
	
	/// Get global variables for the following procedures.
	Wave/T ImageList = :Red2DPackage:ImageList
	Variable numOfImages = DimSize(ImageList,0)
	Wave TopImage = $ImageList[0]
						
	NVAR U_Xmax = :Red2DPackage:U_Xmax
	NVAR U_Ymax = :Red2DPackage:U_Ymax
	U_Xmax = Dimsize(TopImage,0) - 1		// These global variables are used in clac_q and circular average.
   U_Ymax = Dimsize(TopImage,1) - 1
	
	/// Calculate q and phi at each pixel.
	R2D_calc_qMap() // q is rounded and stored in qindexMap. Solid angle correction factor.
	R2D_calc_phiMap(phi_offset) // phi is rounded and stored in phiMap. phi_offset is the offset of starting angle (deg) in the azimuthal plot.
	

	/// Reorganize data into Azimuthal 2D profile
	DoWindow/H
	Print "In preparation ..."
	Doupdate
	variable i
	For(i=0; i<numOfImages; i++)
			
		Variable t0=StartMsTimer // Start Timer
				
		Azimuthal2D_worker($(ImageList[i]), dfAz2d) // Convert
				
		Print i+1,"/",numOfImages, ";", StopMSTimer(t0)/1E+6, "sec/image" //End Timer
				
	Endfor

End


/// Calculate phi of each pixel
Function R2D_calc_phiMap(phi_offset)
	variable phi_offset	// offset for the starting point of phi in the azimuthal plot, deg
	
	variable/C phi_offset_complx = exp(sqrt(-1)*(-1*phi_offset/180*pi))	// convert the offset deg angle to a normalized complex number
		
	/// Get Top Image and duplicate Top Image as AzimuthalROI and save it in package folder. Only going when W_Imageslist exist.
	Wave/T ImagesList = :Red2DPackage:ImageList
	Variable numOfImages = DimSize(ImagesList,0)
	Wave TopImage = $(ImagesList[0])
	
	/// Get global variables
	NVAR U_Xmax = :Red2DPackage:U_Xmax
	NVAR U_Ymax = :Red2DPackage:U_Ymax
	NVAR U_X0 = :Red2DPackage:U_X0
	NVAR U_Y0 = :Red2DPackage:U_Y0
	
	U_Xmax=Dimsize(TopImage,0)-1
	U_Ymax=Dimsize(TopImage,1)-1
	
	Duplicate/O TopImage, :Red2DPackage:phiMap
	wave phiMap = :Red2DPackage:phiMap
	
	variable i, j
	For(i=0;i<U_Xmax+1;i++)
		For(j=0;j<U_Ymax+1;J++)
			variable/C z0 = cmplx(i-U_X0,-j+U_Y0)	// convert relative x-y coordinates to polar complex coordinates. magnitude is stored in the real part and phi in imaginary.
			variable/C z = r2polar(z0*phi_offset_complx)		// rotate phi complex vector with the offset
//			variable/C z = r2polar(cmplx(i-U_X0,-j+U_Y0)) // convert relative x-y coordinates to polar complex coordinates. magnitude is stored in the real part and phi in imaginary.
			if(imag(z)>=0)
				phiMap[i][j] = floor(imag(z)/pi*180) //get phi of selected pixel and store as an integer in the phiMap.
			else
				phiMap[i][j] = floor(imag(z)/pi*180+360) //To adjust igor phi rule (0->+180, 0->-180) to my phi rule (0->360)
			endif
		Endfor
	Endfor
	
End

/// Convert to Azimuthal2D loop
ThreadSafe Static Function Azimuthal2D_worker(pWave, dfAz2d)
	Wave pWave
	string dfAz2d
	
	/// Set global variables, which are shared with the other procedures. 
	NVAR Xmax = :Red2DPackage:U_Xmax
	NVAR Ymax = :Red2DPackage:U_Ymax
	NVAR qnum = :Red2DPackage:U_qnum
	NVAR qmin = :Red2DPackage:U_qmin
	NVAR qres = :Red2DPackage:U_qres
	Wave qScalarIndexMap = :Red2DPackage:qScalarIndexMap
	Wave phiMap = :Red2DPackage:phiMap
	Wave SolidAngleMap = :Red2DPackage:SolidAngleMap
		
   /// Create a refwave to store values. added int and count number.
   	make/FREE/D/O/N=(qnum, 360) rawSum, count, intensity
//   	make/FREE/D/O/N=(qnum, 360) err
	
  	/// Start circular average
   variable i, j, qindex, phi
   count = 0 //initialize count
   
   /// Add pixels to get circular sum
   for(i=0; i<Xmax+1; i++) //gXmax is the coordinates.
    	for (j=0; j<Ymax+1; j++)

    		if(pWave[i][j]<0)
    			//skip add when intensity is negative.
    		else
    			qindex = qScalarIndexMap[i][j] //thetaMap[i][j] contains normalized theta values (Integer) by a minimum theta value deterimined above.
    			phi = phiMap[i][j]

    			// ADD INTENSITY.
	 	  	 	rawSum[qindex][phi] += pWave[i][j]/SolidAngleMap[i][j]
	 	  	 	count[qindex][phi] += 1 //calculate the pixel number that corresponds to distance r, considering the mask.
	 	   endif
	 	   
	 	endfor
	 endfor
	 
	/// Calcuate mean
	/// Note that Error at each pixel ERR = sqrt(I).
  	/// The error propagation leads to SUERR = {SUM([sqrt(I)]^2)}^0.5 = {SUM[I]}^0.5.
  	/// So you can simply calcualte the SUM(I) to get the Err.
	intensity = rawSum/count
//	err = rawSum^0.5/count
	
	SetScale/P x, qmin, qres, "Å\S−1\M", intensity
//	SetScale/P x, qmin, qres, "Å\S−1", err
	SetScale/P y, 0, 1, "deg", intensity
//	SetScale/P y, 0, 1, "deg", err
	
	string newintname = dfAz2d + NameofWave(pWave)
//	string newinterrname = dfAz2d + NameofWave(pWave) + "_ERR"
	duplicate/O/D intensity $newintname
//	duplicate/O/D err $newinterrname
	
End

// *** QxQy conversion
Static Function R2D_QxQy2D()
//	variable phi_offset
	
	/// Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and a imagelist.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	/// Get global variables for the following procedures.
	Wave/T ImageList = :Red2DPackage:ImageList
	Variable numOfImages = DimSize(ImageList,0)
	Wave TopImage = $ImageList[0]
						
	NVAR U_Xmax = :Red2DPackage:U_Xmax
	NVAR U_Ymax = :Red2DPackage:U_Ymax
	U_Xmax = Dimsize(TopImage,0) - 1		// These global variables are used in clac_q and circular average.
   U_Ymax = Dimsize(TopImage,1) - 1
	
	/// Calculate q and phi at each pixel.
	R2D_calc_qMap() // q is rounded and stored in qindexMap. Solid angle correction factor.
	
	// Create a folder to save converted images
	NewDataFolder/O QxQy2D
	string dfQxQy2d = GetDataFolder(1, QxQy2D) + ":" + "QxQy2D"
	string outputpath	// Create path for the newly created QxQy image

	/// Reorganize data into QxQy coordinates
	DoWindow/H
	Print "In preparation ..."
	Doupdate
	variable i
	For(i=0; i<numOfImages; i++)
			
		Variable t0=StartMsTimer // Start Timer
		outputpath = dfQxQy2d + ":" + ImageList[i]
		R2D_QxQy2D_worker($(ImageList[i]), outputpath) // Convert
				
		Print i+1,"/",numOfImages, ";", StopMSTimer(t0)/1E+6, "sec/image" //End Timer
				
	Endfor

End

/// Convert intensity pixel map to intensity qx, qy map
/// 2024-06-25 properly worked
/// the effect of qz is ignored. The intensity is stacked on qz direction (qx, qy, SUM(qz)).
/// Making qz effective is not difficult. I just need to create a 3D qxqyqz wave to store the photon counts.
/// However, visualizing the 3D wave could be troublesome.
ThreadSafe Static Function R2D_QxQy2D_worker(pWave, QxQy2D_path)
	wave pWave	// target 2D scattering image
	string QxQy2D_path	// fullpath of output QxQy2D
	
	/// Set global variables, which are shared with the other procedures. 
	NVAR Xmax = :Red2DPackage:U_Xmax
	NVAR Ymax = :Red2DPackage:U_Ymax
	NVAR qx_index_min = :Red2DPackage:U_qx_index_min	// using the q_index and q_resolution can recover round q-values.
	NVAR qx_index_num = :Red2DPackage:U_qx_index_num
	NVAR qy_index_min = :Red2DPackage:U_qy_index_min
	NVAR qy_index_num = :Red2DPackage:U_qy_index_num
	NVAR qres = :Red2DPackage:U_qres
	wave qVecMap = :Red2DPackage:qVecMap		// qvecMap is evenly spaced vector map of q. The spacing is U_qres.
	wave qVecIndexMap = :Red2DPackage:qVecIndexMap	// = round(qvecMap/U_qres)
	wave qVecIndexMap_withOffset = :Red2DPackage:qVecIndexMap_withOffset	// = qVecIndexMap[p][q][r] - qvec_min[r] ensure the index is always positive. See R2D_calc_qMap.
	Wave SolidAngleMap = :Red2DPackage:SolidAngleMap
	
   // pwave is a p(pixel)-based intensity image, IpImage
   // QxQy2D is a q-based intensity image
   // I want to convert the Ip-image to Iq-image
   // To do this conversion, I need a conversion map
   // qvecMap is a p-based q-vector map, telling us the qx, qy, and qz, of each pixel, stored as a beam (igor term)
   // qscalarMap is a scalar map of q-vector
   // averaging the photon counts in the pixels with the same qVecIndexMap_offset gives QxQy map.
   // notably, not all q-values have intensity-values. There will be some null qxqy pixel.
   
   // How to do this conversion with the programming?
   // create an empty q-based image
   make/FREE/D/O/N=(qx_index_num, qy_index_num) tempSum_map, count_map	// temporary waves to store photon counts in qx qy coordinates
   
   // remap IpImage to IqImage based on the qvecMap (p-based conversion map)
   variable i, j, row, col, phcount, qx, qy, qx_index, qy_index, qx_index_offset, qy_index_offset
   count_map = 0 //initialize count map
   
   for(i=0; i<Xmax+1; i++)	// scan each pixel in the IpImage and remap the intensity value to the corresponding IqImage based on the conversion matrxi qvecMap.
    	for (j=0; j<Ymax+1; j++)
			phcount = pWave[i][j]
    		if(phcount<0 || numtype(phcount) == 2)
    			//skip add when intensity is negative or NaN.
    		else
    			qx_index_offset = qVecIndexMap_withOffset[i][j][0]	// x-layer. get qx index (with offset ) in this p-pixel
    			qy_index_offset = qVecIndexMap_withOffset[i][j][1]	// y-layer. get qy index similarily.

    			// Sum up photon counts
	 	  	 	tempSum_map[qx_index_offset][qy_index_offset] += phcount/SolidAngleMap[i][j]
	 	  	 	count_map[qx_index_offset][qy_index_offset] += 1 //calculate the pixel number that corresponds to distance r, considering the mask.
	 	   endif
	 	   
	 	endfor
	 endfor	
	
	MatrixOP/FREE QxQy2D = tempSum_map/count_map	// normalize the intensity by the counts
	
	SetScale/P x, qx_index_min*qres, qres, "Å\S−1\M", QxQy2D
	SetScale/P y, qy_index_min*qres, qres, "Å\S−1\M", QxQy2D
	
	duplicate/O/D QxQy2D, $QxQy2D_path

End

// *************************
// *** Get 2D stats
// *************************

Function R2D_TotalCount()
	
	// Check if in the image folder. Error_ImgaesExist will create a Red2Dpackage folder.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	// Create an image list
	R2D_CreateImageList(1)  // 1 for name order, 2 for date created order
	SVAR ImageList = :Red2DPackage:U_ImageList
	variable numOfImages = itemsInList(ImageList)
	
	// Check if intensity image exists
	DoWindow IntensityImage
	string topimage_name
	if(V_flag == 1) // if the window exist, try to create ROI
//		topimage_name = StringFromList(0, ImageList)
		topimage_name = StringFromList(0, ImageNameList("IntensityImage", ";"))
		// Create ROI if exists (this function report V_flag == 0 if roi does not exist)
		ImageGenerateROIMask/W=IntensityImage/E=1/I=0 $topimage_name	// ImageGenerateROIMask does not directly accept wave, it needs instance name
		// by default ImageGenerateROIMask creates a mask wave, by using /E=1/I0 to make it ROI wave or mask outsie of ROI.
		wave/Z M_ROIMask
	endif
	
	Make/T/O/N=(numOfImages, 3) :Red2DPackage:TotalCount
	Wave/T TotalCount = :Red2DPackage:TotalCount
	SetDimLabel 1, 0, ImageName, TotalCount
	SetDimLabel 1, 1, TotalCount, TotalCount
	SetDimLabel 1, 2, Count_per_pixel, TotalCount
	Print "ImageName TotalCount"
	variable i
	For(i=0; i<numOfImages; i++)
		ImageStats/R=M_ROIMask/M=1 $StringFromList(i, ImageList)
		TotalCount[i][0] = StringFromList(i, ImageList)
		TotalCount[i][1] = num2str(V_avg*V_npnts)
		TotalCount[i][2] = num2str(V_avg)
		Print TotalCount[i][0] + " " + TotalCount[i][1] + " " + TotalCount[i][2]
	Endfor
	Edit/K=1 TotalCount.ld
	
	KillWaves/Z M_ROIMask
	
End


Function R2D_GetBeamCenter()

	/// Check if in the image folder. Error_ImgaesExist will create a Red2Dpackage folder.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	/// Create an image list
	R2D_CreateImageList(1)  // 1 for name order, 2 for date created order
	
	Wave/Z/T ImageList = :Red2DPackage:ImageList
	Variable NumOfImages = DimSize(ImageList,0)
	Make/O/T/N=(NumOfImages, 3) :Red2DPackage:BeamCenters
	Wave/T BeamCenters = :Red2DPackage:BeamCenters
	SetDimLabel 1, 0, ImageName, BeamCenters
	SetDimLabel 1, 1, x, BeamCenters
	SetDimLabel 1, 2, y, BeamCenters
	Variable i
	Print "ImageName x y"
	For(i=0; i<NumOfImages; i++)
		Wave target = $ImageList[i]		
		ImageStats target
		BeamCenters[i][0] = ImageList[i]
		//Get max intensity position; x stored in col1, y stored in col2
		BeamCenters[i][1] = num2str(V_maxRowLoc)  // x in a 2D image (horizontal axis) = rows in a 2D table (veritcal axis)
		BeamCenters[i][2] = num2str(V_maxColLoc)  // y in a 2D image (vertical axis) = columns in a 2D table (horizontal axis)
		// 2021-07-25 I have checked the fit_standard proc and circular average proc.
		// These procs properly took the image and table difference into account.
		Print BeamCenters[i][0] + " " + BeamCenters[i][1] + " " + BeamCenters[i][2]
	Endfor
	Edit BeamCenters.ld
End

// *************************
// *** Export 2D
// *************************
Function R2D_Export2D(WhichName, type)
	Variable WhichName	//0 for wave name, 1 for sample name.
	Variable type  //0 for tiff, 1 for png/jpeg

	// Check if in the image folder. Error_ImgaesExist will create a Red2Dpackage folder.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	// Create an image list
	R2D_CreateImageList(1)  // 1 for name order, 2 for date created order
	SVAR ImageList = :Red2DPackage:U_ImageList
	variable numOfImages = itemsInList(ImageList)
		
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
	
	make/T/FREE/O/N=(3,5) tagw
	tagw[0][] = {"305", "Software", "2", "38", "Red2D (https://github.com/hurxl/Red2D)"}	// software
	
	Variable i
	
	// Create an image file and append a header
	For(i=0; i < numOfImages; i++)

		WaveNam = StringFromList(i, ImageList)	// Get wave name
		SampleName = WaveNam  // default value
		Trans = "NaN"  // default value
		
		// if datasheet exist, get trans and sample name of the corresponding 2D wave.
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
		
		tagw[1][] = {"306", "DateTime", "2", "38", Secs2Date(DateTime,-2) + " " + time()}	// date and time
		header1 = ""	// Clear the content in header1 from previous loop
		header1 += "Experiment name: " + pxpName +"\r"
		header1 += "Datafolder path: " + DatafolderPath + "\r"
		header1 += "Sample name: " + SampleName + "\r"
		header1 += "Wave name: " + WaveNam + "\r"
		header1 += "SDD: " + num2str(SDD) +"m \r"
		header1 += "Wavelength : " + num2Str(Wavelength) + "A \r"
		header1 += "Transmittance: " + Trans +"\r"
		tagw[2][] = {"270", "ImageDescription", "2", num2str(strlen(header1)), header1}
		
		// Set file name
		Switch(WhichName)
			Case 1:
				If(Strlen(SampleName) == 0)	// if sample name does not exist, use image name
					filename = WaveNam
				Else
					filename = SampleName //	set file name
				Endif
				break
			
			default:
				filename = WaveNam //	set file name
				break
		Endswitch
		
//		Close/A
//		Open/P=FolderPath refnum as filename	// Write a header
//		fprintf refnum, "%s", header0
//		fprintf refnum, "%s", header1
//		Close refnum
		
//		Duplicate/O/D $(WaveNam + "_q"), q_A
//		Duplicate/O/D $(WaveNam + "_2t"), TwoTheta
//		Duplicate/O/D $(WaveNam + "_i"), I_cm
//		Duplicate/O/D $(WaveNam + "_s"), s_cm
		
		If(type == 0)
//			Save/A/G/W/P=FolderPath q_A, I_cm, s_cm as filename	// save seletected waves in a txt file as filename in folderpath.
//			ImageSave/O/T="tiff"/U/DS=32/WT=tagw/P=FolderPath $WaveNam as filename
			ImageSave/O/T="tiff"/U/DS=32/P=FolderPath $WaveNam as filename + ".tif"
		Else
			ImageSave/O/T="jpeg"/P=FolderPath/U $WaveNam as filename + ".jpeg"
//			Save/A/G/W/P=FolderPath TwoTheta, I_cm, s_cm as filename	// save seletected waves in a txt file as filename in folderpath.			
		Endif
		
	Endfor

//	KillWaves/Z q_A, TwoTheta, I_cm, s_cm

End
