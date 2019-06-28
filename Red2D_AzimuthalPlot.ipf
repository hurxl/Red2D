#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

///////////////Azimuthal Mask Panel and Switch/////////////////
Function Red2D_AzimuthalPlotPanel()
	//Check if in images folder by checking if there is an imagelist in the package folder.
	If(Red2Dimagelistexist() == -1)
		return -1
	Endif	

	//Set global variables, which are shared with the other procedures.
	If(DatafolderExists("Red2DPackage")==0)
		NewDataFolder :Red2DPackage
	Endif
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
		Variable/G U_r0, U_dr, U_X0, U_Y0
	SetdataFolder saveDFR

	//Create a new panel to collect parameter to perform circular average
	NewPanel/K=1/N=SectorMask/W=(200,200,420,400)
	SetVariable setvar0 title="r0 [pixel]",pos={10,10},size={200,25},limits={0,+inf,1},fSize=13, value=U_r0
	SetVariable setvar1 title="dr [pixel]",pos={10,35},size={200,25},limits={0,+inf,1},fSize=13, value=U_dr
	Button button0 title="Show Azimuthal ROI",size={150,25},pos={35,80},proc=ButtonProcShowAzimuthalROI
	Button button1 title="Plot Intensity",size={150,25},pos={35,120},proc=ButtonProcPlotAzimuthalROI
	DrawText 10,180,"Set DataFolder to where images exist"
End

Function ButtonProcShowAzimuthalROI(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			ShowAzimuthalROI() 		
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ButtonProcPlotAzimuthalROI(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			DoAzimuthalPlot()	 		
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function ShowAzimuthalROI()
	
	///////ERR CHECK///////
	//Check if in images folder by checking if there is an imagelist in the package folder.
	If(Red2Dimagelistexist() == -1)
		return -1
	Endif
	
	//Get Top Image and duplicate Top Image as AzimuthalROI and save it in package folder. Only going when W_Imageslist exist.
	Wave/T ImagesList = :Red2DPackage:ImageList
	Variable numOfImages = DimSize(ImagesList,0)
	Wave TopImage = $(ImagesList[0])
	
	///////Create an AzimuthalROI////////
	//Set global variables, which are shared with the other procedures. 
	If(DatafolderExists("Red2DPackage")==0)
		NewDataFolder :Red2DPackage
	Endif
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
		Variable/G U_Xmax, U_Ymax, U_r0, U_dr, U_X0, U_Y0
		U_Xmax=Dimsize(TopImage,0)-1
		U_Ymax=Dimsize(TopImage,1)-1
	
		Duplicate/O TopImage, AzimuthalROI, Az_phiMap
		AzimuthalROI = 0 //type 1 for the process below. 1 denotes the pixels to be masked. 0 denotes the pixels to be used.
		Az_phiMap = 0
		
	variable i, j		
	For(i=0;i<U_Xmax+1;i++)
		For(j=0;j<U_Ymax+1;J++)
			variable/C z = r2polar(cmplx(i-U_X0,-j+U_Y0)) //convert relative x-y coordinates to polar complex coordinates. magnitude is stored in the real part and phi in imaginary.
			if(imag(z)>=0)
				Az_phiMap[i][j] = floor(imag(z)/pi*180) //get phi of selected pixel and store as an integer in the phiMap.
			else
				Az_phiMap[i][j] = floor(imag(z)/pi*180+360) //To adjust igor phi rule (0->+180, 0->-180) to my phi rule (0->360)
			endif
			If(abs(U_r0^2 - ((i-U_X0)^2 + (j-U_Y0)^2)) < U_dr^2) //Type 0 into Mask if in the ROI.
				AzimuthalROI[i][j] = 1
			Endif
		Endfor
	Endfor

	//Append AzimuthalROI to Top Image
	RemoveImage/Z AzimuthalROI //ImageName is the actual Image Name, not the wave name
	AppendImage/T AzimuthalROI //When appending it should be wave name
	ModifyImage AzimuthalROI explicit=1, eval={0,0,0,0,0}, eval={1,50000,50000,50000,30000} // eval is color. (eval={value, red, green, blue [, alpha]})
	SetdataFolder saveDFR
	
	///////Prepare for AzimuthalPlot////////
	//Create a new folder to store the generated 1D data.
	If(DatafolderExists("AzimuthalPlot")==0)
		NewDataFolder AzimuthalPlot
	Endif
	
	//Create a x-axis for the Azimuthal plot.
	Make/O/N=360 Azimuthal_degree
	Azimuthal_degree = x
	Duplicate/O Azimuthal_degree, :AzimuthalPlot:Azimuthal_degree //Save it in the DF AzimuthalPlot.
	Killwaves Azimuthal_degree
	
End


Function DoAzimuthalPlot()

	//Check if in images folder by checking if there is an imagelist in the package folder.
	If(Red2Dimagelistexist() == -1)
		return -1
	Endif	
	
	//Set parameters
	Wave AzimuthalROI = :Red2Dpackage:AzimuthalROI
	Wave phiMap = :Red2Dpackage:Az_phiMap
	Wave/T ImagesList = :Red2DPackage:ImageList
	Variable numOfImages = DimSize(ImagesList,0)
	
	//Set global variables, which are shared with the other procedures. 
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
		Variable/G U_Xmax, U_Ymax, U_r0, U_dr, U_X0, U_Y0
		NVAR Xmax = U_Xmax
		NVAR Ymax = U_Ymax
		NVAR r0 = U_r0
		NVAR dr = U_dr
		NVAR X0 = U_X0
		NVAR Y0 = U_Y0
	SetdataFolder saveDFR
	
	//Make two 1D waves to store the data.
	Make/O/N=360 count, Azimuthal_int, Azimuthal_err, Azimuthal_I
	Azimuthal_int = 0 //Initialize Azimuthal_I
	Azimuthal_err = 0
	
	//Do AzimuthalPlot.
	variable p, i, j, phi
	For(p=0;p<numOfImages;p++)
		count = 0
		Wave pWave = $(ImagesList[p]) //set target
		Print ImagesList[p]
		
		//Start Timer
		Variable t=StartMsTimer
		
			For(i=0;i<Xmax+1;i++)
				For(j=0;j<Ymax+1;J++)
				
					If(AzimuthalROI[i][j]==1) //If selected pixel is in ROI
						If(pWave[i][j] >= 0)
							phi = phiMap[i][j] //Get phi of the selected pixel.
							Azimuthal_I[phi] += pWave[i][j] //Add intensity
							count[phi] += 1 //count the number of pixels with the same phi.
						Endif
					Endif
					
				Endfor
			Endfor
			
		Azimuthal_int = Azimuthal_I/count
		Azimuthal_err = Azimuthal_I^0.5/count
		
		DFREF saveDFR = GetDataFolderDFR()
		SetDataFolder AzimuthalPlot
			String NewName = ImagesList[p]+"_Az"
			String NewName_ERR = ImagesList[p]+"_Az_ERR"
			Duplicate/O Azimuthal_int, $(NewName)
			Duplicate/O Azimuthal_err, $(NewName_ERR)
		SetdataFolder saveDFR
		
		//End Timer
		Print p+1,"/",numOfImages, ";", StopMSTimer(t)/1E+6, "sec/image"
		
	Endfor
	Killwaves Azimuthal_int, Azimuthal_err, Azimuthal_I//, count
	
	Print "AzimuthalPlot Success"
	Print "See the data folder AzimuthalPlot"
End

