#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// *************************
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
		String/G U_AllMaskName, U_automask_name
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

	PopupMenu popup1 title="Set all mask", pos={15,120}, fSize=13, value=R2D_GetMaskList_simple(), proc=Update_AllMaskName
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
// Normalize 2D images
// *************************

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
			
			// Create a refcell in the new folder with the selected cell path
			// The sensitivity standards, e.g., H2O and lupolen, should not have a constant intensity on the 2D images.
			// There should be a natural decrease in the intensity as the pixels going out from the beam center
			// because of the decrease of solid angle per pixel.
			// Therefore, when creating the pixel sensitivity file, I should remove the natural decrease from the file.
			Duplicate/O $SensitivityPath, :Red2Dpackage:sensitivity
			Wave Sensitivity = :Red2Dpackage:sensitivity
			Multithread Sensitivity[][] = Sensitivity[p][q] == 0 ? NaN : Sensitivity[p][q]  // convert zero value to NaN to remove these pixels from calculation.
			R2D_calc_qMap() // calculate solidangle correction map. the function locates in the circular average ipf.
			Wave SolidAngleCorrMap = :Red2DPackage:SolidAngleCorrMap // get the solidangle wave created by above function.
			MatrixOP/O Sensitivity = Sensitivity*SolidAngleCorrMap
			ImageStats Sensitivity
			Sensitivity /= V_avg
			Print "A sensitivity correction file was created and stored in Red2Dpackage datafolder."

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function R2D_TimeAndTrans2D()

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
	
	/// Save new images into another folder
	String ImageFolderName = "Images_TT"
	variable i
	For(i = 0; i < 100; i++)
		If(DataFolderExists(ImageFolderName) == 0)
			break
		Else
			ImageFolderName = "Images_TT_" + num2str(i+1)
		Endif
	Endfor
	NewDataFolder $ImageFolderName
	
	// Duplicate the images to the new folder and set the new folder as the active folder
	variable j
	For(j = 0; j < numOfImages; j++)
//		Print ImageList[j]
		wave refwave = $ImageList[j]
		string newname = ":" + ImageFolderName + ":" + NameOfWave(refwave)
		Duplicate/O refwave $newname
	Endfor
	String PackageFolderPath = ":" + ImageFolderName + ":Red2DPackage"
	DuplicateDataFolder/O=1 Red2DPackage $PackageFolderPath
	SetDataFolder $ImageFolderName
	
	/// Normalization
	wave/T Datasheet = :Red2DPackage:Datasheet
	Make/FREE/T/O/N=(numOfImages) Datasheet_ImageName = Datasheet[p][%ImageName]  // the number of rows of datasheet will not exceed numOfImages.
	Variable Time_s, Trans
	For(i=0; i<numOfImages; i+=1)
		
		/// Get target name from Imagelist and create an errorbar wave
		wave image_i = $ImageList[i]
		Redimension/D image_i
//		Duplicate/O/D image_i, $(ImageList[i] + "_s")
//		wave image_s = $(ImageList[i] + "_s")
//		Multithread image_s = sqrt(image_i)

		
		// Get time and trans
		FindValue/TEXT=(ImageList[i]) Datasheet_ImageName		// One wave must be found here because we have checked the consistence bwteen the datasheet and 1D waves in the beginning.//		Time_s = str2num(Datasheet[V_value][%Time_s])
		Time_s = str2num(Datasheet[V_value][%Time_s])
		Trans = str2num(Datasheet[V_value][%Trans])
				
		/// Do the correction.
		image_i = image_i/Time_s/Trans
//		image_s = image_s/Time_s/Trans
		
		Print NameofWave(image_i) +"/"+ num2str(Time_s) +"/"+ num2str(Trans)
//		Print NameofWave(image_s) +"/"+ num2str(Time_s) +"/"+ num2str(Trans)
		
	Endfor

End

// Subtract a 2D image from all images in current datafolder
Function R2D_Cellsubtraction2D()

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
	

	Killwindow/Z CellsubtractionPanel2D
	NewPanel/K=1/W=(100,100,500,250) as "Cell subtraction"
	RenameWindow $S_name, CellsubtractionPanel2D
	
	TitleBox WSPopupTitle1,pos={80,23}, frame=0, fSize=14, title="Select a wave of cell or air to subtract"
	Button CellSelector,pos={30,50},size={340,23}, fSize=14
	MakeButtonIntoWSPopupButton("CellsubtractionPanel2D", "CellSelector", "CellPopupWaveSelectorNotify", popupWidth = 400, popupHeight = 600, options=PopupWS_OptionFloat)
	PopupWS_MatchOptions("CellsubtractionPanel2D", "CellSelector", matchStr = "*", listoptions = "DIMS:2,TEXT:0")
	PopupWS_SetPopupFont("CellsubtractionPanel2D", "CellSelector", fontsize = 13)
	///MakeButtonIntoWSPopupButton is a builtin function in Igor Pro.
	Button bt0,pos={150,100},size={110,23}, fSize=14, proc=CellSubtractButtonProc2D,title="Subtract Cell"
	
End

Function CellSubtractButtonProc2D(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			

			Wave/T ImageList = :Red2DPackage:ImageList
			Variable numOfImages = DimSize(ImageList,0)
			
			//////////////////////////////GET CELL WAVE////////////////////////////////
			String CellPath = PopupWS_GetSelectionFullPath("CellsubtractionPanel2D", "CellSelector")
			If(cmpstr(CellPath, "(no selection)", 0) == 0)
				Print "False"
				Abort "No selection."
			Endif
			
			/// Crate a new folder to save new images
			String ImageFolderName = "Images_c"
			variable i
			For(i = 0; i < 100; i++)
				If(DataFolderExists(ImageFolderName) == 0)
					break
				Else
					ImageFolderName = "Images_c_" + num2str(i+1)
				Endif
			Endfor
			NewDataFolder $ImageFolderName
	
			// Duplicate the images to the new folder and set the new folder as the active folder
			variable j
			For(j = 0; j < numOfImages; j++)
				wave refwave = $ImageList[j]
				string newname = ":" + ImageFolderName + ":" + NameOfWave(refwave)
				Duplicate/O refwave $newname
			Endfor
			String PackageFolderPath = ":" + ImageFolderName + ":Red2DPackage"
			DuplicateDataFolder/O=1 Red2DPackage $PackageFolderPath
			SetDataFolder $ImageFolderName
			
			// Create a refcell in the new folder with the selected cell path
			Duplicate/O/FREE $(CellPath), refcell
			
//			Duplicate/O/FREE $(RemoveEnding(CellPath,"_i") + "_s"), refcell_s
			
//			wave testwave = $(StringFromList(0, IntList))
//			If(Dimsize(refcell,0) != Dimsize(testwave,0))	
//				Print "False"
//				Killwaves refcell, refcell_s
//				Abort "1D waves in current datafolder do not match ImageName in datasheet. ImageName must have the same order as 1D waves shown in data browser."
//			Endif
			
			/// Duplicate datafolder to backup data before nomalization.	
//			String dfp0 = RemoveEnding(GetDataFolder(1), ":")
//			String dfp1 = RemoveEnding(GetDataFolder(1), ":") + "c"	// initial path
//			String DFname1 = GetDataFolder(0) + "c"	// initial name
//			variable i
//			For(i = 0; i < 100; i++)
//				If(DataFolderExists(dfp1) == 0)
//					break
//				Endif
//				dfp1 = RemoveEnding(GetDataFolder(1), ":") + "c_" + num2str(i)
//				DFname1 = GetDataFolder(0) + "c_" + num2str(i)
//			Endfor
//	
//			RenameDataFolder $dfp0, $DFname1
//			DuplicateDataFolder $dfp1, $dfp0

			///////////////////////////SUBTRACT CELL////////////////////////////////
//			String targetName
			For(i=0;i<numOfImages; i+=1)
				//Set reference of target wave in current folder. Only deal with waves having name in refname(Datasheet).
//				targetName = RemoveEnding(StringFromList(i, IntList), "_i")
				Wave target = $ImageList[i]
//				Wave Wave1D_s = $(targetName + "_s")

				// Subtract cell
				target -= refcell
//				Wave1D_s = (Wave1D_s^2 + refcell_s^2)^0.5
				
			Endfor
	
			Killwindow CellsubtractionPanel2D
			Print CellPath
			Print "is subtracted from"
			Print ImageList
					
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


// Add multiple 2D images together.
Function R2D_Add2DImages(refresh)
	variable refresh
	
	/// Check if in the image folder. Error_ImagesExist will create a Red2Dpackage folder and a imagelist.
	If(R2D_Error_ImagesExist() == -1)
		Abort
	Endif
	
	DFREF saveDFR = GetDataFolderDFR()
	If(DatafolderExists("Red2DPackage")==0)
		NewDataFolder :Red2DPackage
	Endif
	SetDataFolder Red2DPackage
	String/G U_StrToMatch, U_NewWaveName
	U_NewWaveName = "temporary"
	Variable/G U_NumToCombine
	U_NumToCombine = 1
	Make/T/O/N=0 MatchedWaves // Create an empty text wave for listbox to refer
	SetDataFolder saveDFR
	
	//Create a new panel to collect parameters
	If(refresh == 0)
		KillWindow/Z Add2D
		NewPanel/K=1/N=Add2D/W=(200,200,900,500)
	Endif
	
	SetVariable setvar1 title="String to match", pos={10,20},size={300,25}, fSize=13, value=U_StrToMatch, help={"Use * as a wildcard. e.g. *test*"} //Set match string
	PopupMenu popup0 title="Sort list by ",value="Name;Date created",fSize=13, pos={10, 53}
	Button button0 title="Show list",size={100,23},pos={210,50},proc=ButtonProcShowList // Activate showlist script
	ListBox lbCW listWave=MatchedWaves, mode=0, size={360,280}, pos={330,10}, fSize=13, userColumnResize=1 // Make a listbox on the panel
	
	//Set parameters and trigger image combine script.
	SetVariable setvar2 title="Number of images to add",pos={10,130},size={300,25},limits={1,inf,1},fSize=13, value=U_NumToCombine // Set number of waves to combine
	SetVariable setvar3 title="New wave name", pos={10,160},size={300,25}, fSize=13, value=U_NewWaveName //Set match string
	CheckBox check0 title="Use original name",value=0,fSize=13, pos={10, 193}
	CheckBox check0 help={"The 1st image in each group will be used as the new image name. If checked, new wave name will be overwritten."}
	CheckBox check1 title="Delete original files after added",value=0,fSize=13, pos={10, 220}
	Button button1 title="Add Waves",size={100,23},pos={50,255},proc=ButtonProcCombineWaves // Trigger combine waves script
	Button button2 title="Refresh",size={100,23},pos={180,255},proc=ButtonProcRefreshAdd2D // Trigger combine waves script
	

End

Function ButtonProcRefreshAdd2D(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			R2D_Add2DImages(1)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProcShowList(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
		
			SVAR StrToMatch = :Red2DPackage:U_StrToMatch	
			String ListByDate = wavelist(StrToMatch,";","DIMS:2") //Get wavelist from current folder with matching string and selected dimensions.
			String ListByName = SortList(ListByDate, ";", 8)	// Sort the list by name (default wavelist get by date created)
			Variable NumInList = itemsinlist(ListByDate) // Get number of items in List
			

//			Make/T/O/N=(NumInList) :Red2DPackage:MatchedWaves  // create a text wave to store the namelist
//			Wave/T MatchedWaves = :Red2DPackage:MatchedWaves
	
			If(NumInList==0)	
				Print "No wave matches your selection."
				Make/O/T/N=0 :Red2DPackage:MatchedWaves = ""
				Return 0
			Else
					
//				variable i
				ControlInfo popup0
				Variable order = V_Value	// 1 for name, 2 for date created
				If(order == 1)
//					For(i=0;i<NumInList;i+=1)
//						MatchedWaves[i] = StringFromList(i,ListByName)
//					Endfor
					Wave/Z/T reftw = ListToTextWave(ListByName,";")  // ListToTextWave returns a FREE wave
					Duplicate/O/T reftw, :Red2DPackage:MatchedWaves
				Elseif(order == 2)
//					For(i=0;i<NumInList;i+=1)
//						MatchedWaves[i] = StringFromList(i,ListByDate)
//					Endfor
					Wave/Z/T reftw = ListToTextWave(ListByDate,";")  // ListToTextWave returns a FREE wave
					Duplicate/O/T reftw, :Red2DPackage:MatchedWaves
				Endif
				
				
				Print Num2str(NumInList) + " items found."
					
			Endif
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

// Use to add Intensity of 2D data.
Function ButtonProcCombineWaves(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
		
			/// Get info of target
			Wave/T MatchedWaves = :Red2DPackage:MatchedWaves	
			SVAR NewWaveName = :Red2DPackage:U_NewWaveName
			NVAR NumToCombine = :Red2DPackage:U_NumToCombine
			Variable NumOfWaves = DimSize(MatchedWaves,0) // Get size of MatchedWaves
			String OriginalWaveName
			
			If(NumOfWaves == 0 || numtype(NumOfWaves) != 0)
				Abort "You may have provided a wrong number of images to combine."
			Elseif(strlen(NewWaveName) == 0)
				Abort "You need to set new wave name."
			Endif
			
			/// Set a new data folder to store the images
			If(DatafolderExists("Added")==0)
				NewDataFolder Added
			Endif
			
			/// Store the Added location
			String AddedDF = GetDataFolder(1)+"Added:"
			
			/// Create a temp wave to store the combined waves
			Duplicate/O $(MatchedWaves[0]), combinedwave
			
			/// Add waves using two for loops.
			variable i, j, k
			ControlInfo check0	// get check box status, 0 for deselected, 1 for selected
			Variable Name_check = V_Value
			ControlInfo check1
			Variable Delete_check = V_Value

			For(i=0;i+NumToCombine <= NumOfWaves; i+=NumToCombine) // Count up initiation number
				k=0 // number of the for top loops
				MultiThread combinedwave = 0 // Initiate combined wave
				
				For(j=0;j<NumToCombine;j+=1) // Count up the iteritation number
					wave refwave = $(MatchedWaves[i+j])
					MultiThread combinedwave += refwave // Add refwave to the combined wave
					If(Delete_check == 1)  // If checked, delete original files.
						KillWaves refwave
					Endif
				Endfor
				
				/// Create name of the combined wave.
				If(Name_check == 1)	// if checked, use original names
					OriginalWaveName = MatchedWaves[i]
					Duplicate/O combinedwave, $(AddedDF+OriginalWaveName)
				Elseif(Name_check == 0)	// if not checked, use new wave names
					If(NumToCombine == NumOfWaves)
						Duplicate/O combinedwave, $(AddedDF+NewWaveName) // If add all the images, do not add sequential number.
					Else
						Duplicate/O combinedwave, $(AddedDF+NewWaveName+"_"+Num2str(k))	
					Endif
				Endif
				k += 1
				
			Endfor
			
			Killwaves combinedwave
			Print "Images were added successfully."
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End


// *************************
// *** Convert 2D NORMAL scattering images to different 2D profiles ***
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
//	DoWindow Azimuthal2D
	DoWindow Convert_2D_coordinates
	If(V_flag == 0)
		NewPanel/K=1/N=Convert_2D_coordinates/W=(800,100,1450,420)
	Else
		DoWindow/F Convert_2D_coordinates
	Endif

//	//Create a new panel to collect parameter to perform circular average
//	If(ParamIsDefault(refresh))
//		KillWindow/Z Azimuthal2D
//		NewPanel/K=1/N=Azimuthal2D/W=(800,100,1150,500)
//	Else
//		GetWindow/Z Azimuthal2D wsize
//		V_left *= ScreenResolution/72
//		V_right *= ScreenResolution/72
//		V_top *= ScreenResolution/72
//		V_bottom *= ScreenResolution/72
//		KillWindow/Z Azimuthal2D
//		NewPanel/K=1/N=Azimuthal2D/W=(V_left,V_top,V_right,V_bottom)
//	Endif
	
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
//	Button button1 title="Convert to qx-qy Images",size={200,23},pos={20,240},proc=ButtonProcqxqy2D
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
			DoAzimuthal2D(phi_offset)
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
//			NVAR phi_offset = :Red2DPackage:U_phiOffset
//			ConvertToqxqyImages()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//////////Main Code//////////
Static Function DoAzimuthal2D(phi_offset)
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
				
		Azimuthal2D($(ImageList[i]), dfAz2d) // Convert
				
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
ThreadSafe Static Function Azimuthal2D(pWave, dfAz2d)
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
	Wave SolidAngleCorrMap = :Red2DPackage:SolidAngleCorrMap
		
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
	 	  	 	rawSum[qindex][phi] += pWave[i][j]*SolidAngleCorrMap[i][j]
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


/// Convert intensity pixel map to intensity qx, qy map
/// 2023-03-12 not complete. Do not work properly.
Function R2D_Convert2IntQxQyMap(pWave, dfIqImage)
	wave pWave	// target 2D scattering image
	string dfIqImage	// datafolder for intensity qx, qy images.
	
	/// Set global variables, which are shared with the other procedures. 
	NVAR Xmax = :Red2DPackage:U_Xmax
	NVAR Ymax = :Red2DPackage:U_Ymax
	NVAR qx_index_min = :Red2DPackage:U_qx_index_min	// using the q_index and q_resolution can recover round q-values.
	NVAR qx_index_num = :Red2DPackage:U_qx_index_num
	NVAR qy_index_min = :Red2DPackage:U_qy_index_min
	NVAR qy_index_num = :Red2DPackage:U_qy_index_num
	NVAR qres = :Red2DPackage:U_qres
	wave qVecIndexMap_withOffset = :Red2DPackage:qVecIndexMap_withOffset
	Wave SolidAngleCorrMap = :Red2DPackage:SolidAngleCorrMap
	
   // pwave is a p(pixel)-based intensity image, IpImage
   // IqImage is a q-based intensity image
   // I want to convert the IpImage to IqImage
   // To do this conversion, I need a conversion map
   // qvecMap is a p-based q-vector map, telling us the qx, qy, and qz, of each pixel, stored as a beam (igor term)
   
   // How to do this conversion with the programming
   // create an empty q-based image
		// needs qx_max, qx_min, qy_max, qy_min
		// the coordinates have evenly spaced and rounded q values, set by q_res (pixel size)
		// the number of points of each coordinate is determined by q_max - q_min / q_res
		// not all q-values have intensity-values.
	make/FREE/D/O/N=(qx_index_num, qy_index_num) rawSum_map, count_map, intensity
	
	// Create a conversion map wave
	// Note: although above maps (will) have a wave scaling based on q-indices (q-values), the row-column indices of above waves start from 0.
	// Therefore, for the convenience in for loops, I need to add convert the q-indices map to row-column indices map.
//	MatrixOP/O qVecIndexMap_withOffset = qVecIndexMap[][][0] - qx_index_min + qVecIndexMap[][][1] - qy_index_min + qVecIndexMap[][][2] - qz_index_min
	
   // remap IpImage to IqImage based on the qvecMap (p-based conversion map)
   variable i, j, row, col
   count_map = 0 //initialize count map
   
   for(i=0; i<Xmax+1; i++)	// scan each pixel in the IpImage and remap the intensity value to the corresponding IqImage based on the conversion matrxi qvecMap.
    	for (j=0; j<Ymax+1; j++)

    		if(pWave[i][j]<0)
    			//skip add when intensity is negative.
    		else
    			row = qVecIndexMap_withOffset[i][j][0]
    			col = qVecIndexMap_withOffset[i][j][1]

    			// ADD INTENSITY.
	 	  	 	rawSum_map[row][col] += pWave[i][j]*SolidAngleCorrMap[i][j]
	 	  	 	count_map[row][col] += 1 //calculate the pixel number that corresponds to distance r, considering the mask.
	 	   endif
	 	   
	 	endfor
	 endfor	
	
	intensity = rawSum_map/count_map	// normalize the intensity by the counts
	
	SetScale/P x, qx_index_min*qres, qres, "Å\S−1\M", intensity
	SetScale/P y, qy_index_min*qres, qres, "Å\S−1\M", intensity
	
	string newintname = dfIqImage + NameofWave(pWave)
	duplicate/O/D intensity $newintname

End

// *************************
// Get stats of 2D images.
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