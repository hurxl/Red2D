#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/////////GUI/////////

Function Red2D_CircularAveragePanel(refresh)
	variable refresh
	
	/// User may directly come to circular average. In that case, the Red2DPackage folder and ImageList does not exist.
	If(DatafolderExists("Red2DPackage")==0)
		NewDataFolder :Red2DPackage
	Endif

	String reflist = wavelist("*",";","DIMS:2") //Get wavelist from current folder limited for 2D waves
	Wave/T reftw = ListToTextWave(reflist,";") // Create a text wave reference containing reflist
	Variable NumInList = itemsinlist(reflist) // Get number of items in List
	Wave TopImage = $reftw[0]

	Duplicate/T/O reftw, :Red2DPackage:ImageList
	
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
		Variable/G U_Xmax, U_Ymax, U_X0, U_Y0, U_SDD, U_Lambda, U_PixelSize, U_tiltX, U_tiltY, U_tiltZ // U_tiltZ is not in use. It is actuall X2. I use X-Y-X type rotation.
		U_Xmax=Dimsize(TopImage,0)-1 //Get image size. Minus 1 because Dimsize is size while Xmax means the coordinates.
		U_Ymax=Dimsize(TopImage,1)-1 //Get image size
		
	SetdataFolder saveDFR
	
	//Create a new panel to collect parameter to perform circular average
	If(refresh == 0)
		NewPanel/K=1/N=CircularAverage/W=(200,200,780,470)
	Endif
	
	SetVariable setvar0 title="X0 [pt]",pos={10,5},size={200,25},limits={-inf,inf,1},fSize=13, value=:Red2DPackage:U_X0
	SetVariable setvar1 title="Y0 [pt]",pos={10,30},size={200,25},limits={-inf,inf,1},fSize=13, value=:Red2DPackage:U_Y0
	SetVariable setvar2 title="SDD [m]",pos={10,55},size={200,25},limits={0,inf,0.1},fSize=13, value=:Red2DPackage:U_SDD
	SetVariable setvar3 title="Tilt_X [º]",pos={10,80},size={200,25},limits={-90,90,1},fSize=13, value=:Red2DPackage:U_tiltX, help={"-90 to 90º"}
	SetVariable setvar4 title="Tilt_Y [º]",pos={10,105},size={200,25},limits={-90,90,1},fSize=13, value=:Red2DPackage:U_tiltY, help={"-90 to 90º"}
	SetVariable setvar5 title="Lambda [A]",pos={10,130},size={200,25},limits={0,inf,0.1},fSize=13, value=:Red2DPackage:U_Lambda, help={"Cu = 1.5418A, Mo = 0.7107A"}
	SetVariable setvar6 title="Pixel Size [um]",pos={10,155},size={200,25},limits={0,inf,1},fSize=13, value=:Red2DPackage:U_PixelSize, help={"Pilatus = 172um, Eiger = 75um"}
	ListBox lb listWave=:Red2DPackage:ImageList, mode=0, pos={220,5}, size={350,250}, fSize=13
	Button button0 title="Circular Average",size={120,25},pos={50,195},proc=ButtonProcCA
	Button button1 title="Refresh",size={120,25},pos={50,235},proc=ButtonProcRefreshListCA
	
End

Function ButtonProcRefreshListCA(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			Red2D_CircularAveragePanel(1)
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
			DoCircularAverage()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


/////////Main Code/////////
/// Perform circular average
Static Function DoCircularAverage()

			/// Check if in the image folder.
			If(Red2Dimagelistexist() == -1)
				return -1
			Endif

			/////////////////Setup variables and folders for process//////////////////
			//Create a new folder to store the generated 1D data.
			variable i
			string dfname
			For(i = 0; i < 100; i++)
				dfname = "Raw1D_"+num2str(i)
				If(DatafolderExists(dfname)==0)
					NewDataFolder $dfname
					string df1d = GetDataFolder(1, $dfname)
					break
				Endif
			Endfor
			
			//Set global variables, which are shared with the other procedures. 
			Wave/T ImageList = :Red2DPackage:ImageList
			Variable numOfImages = DimSize(ImageList,0)
			Wave TopImage = $ImageList[0] // $()convert string to a wave reference
			
			DFREF saveDFR = GetDataFolderDFR()
			SetDataFolder Red2DPackage
			
			Variable/G U_Xmax, U_Ymax, U_X0, U_Y0, U_SDD, U_Lambda, U_PixelSize
			U_Xmax=Dimsize(TopImage,0)-1 //Get image size. Minus 1 because Dimsize is size while Xmax means the coordinates.
		   U_Ymax=Dimsize(TopImage,1)-1 //Get image size
		   
		   /// Calculate q at each pixel, using the info in Red2Dpackage. Solid angle correction factor is generated as well.

		   Calc_qMap()
			Wave qq, theta
			
			SetdataFolder saveDFR
			
			string q_name, theta_name
			q_name = df1d+"qq"
			theta_name = df1d+"theta"
			Duplicate/O/D qq, $q_name
			Duplicate/O/D theta, $theta_name
			Killwaves qq, theta
			
			//////////////////Start circular average///////////////
			For(i=0; i<numOfImages; i++)
			
				Variable t0=StartMsTimer // Start Timer
				
				CircularAverage($(ImageList[i]), df1d) // Do circular average
				
				Print i+1,"/",numOfImages, ";", StopMSTimer(t0)/1E+6, "sec/image" //End Timer
				
			Endfor
								
			//////////////////Create a datasheet///////////////////
			//Red2D_CreateDatasheet()

End

/// Use Euler angles to calcualte the theta and q
Static Function Calc_qMap()

	Variable/G U_Xmax, U_Ymax, U_X0, U_Y0, U_SDD, U_Lambda, U_PixelSize, U_tiltX, U_tiltY, U_tiltZ, U_qnum

	/// Rotation Matrix
	variable Xrad, Yrad, Zrad
	Xrad = U_tiltX/180*pi
	Yrad = U_tiltY/180*pi
	Zrad = U_tiltZ/180*pi
	Make/FREE/D/O/N=(3,3) RotationMatrix
	
	RotationMatrix[0][0] = cos(Yrad)
	RotationMatrix[1][0] = sin(Xrad)*sin(Yrad)
	RotationMatrix[2][0] = -cos(Xrad)*sin(Yrad)
	RotationMatrix[0][1] = sin(Yrad)*sin(0)
	RotationMatrix[1][1] = cos(Xrad)*cos(0)-cos(Yrad)*sin(Xrad)*sin(0)
	RotationMatrix[2][1] = cos(0)*sin(Xrad)+cos(Xrad)*cos(Yrad)*sin(0)
	RotationMatrix[0][2] = cos(0)*sin(Yrad)
	RotationMatrix[1][2] = -cos(Xrad)*sin(0)-cos(Yrad)*cos(0)*sin(Xrad)
	RotationMatrix[2][2] = cos(Xrad)*cos(Yrad)*cos(0)-sin(Xrad)*sin(0)
		
	/// Unit vector in roated plane
	Make/FREE/D/O/N=3 xvec, yvec, zvec, pvec, qvec
	xvec = {1,0,0} 
	yvec = {0,1,0}
	zvec = {0,0,1}
	MatrixOP/FREE/O avec = RotationMatrix x xvec
	MatrixOP/FREE/O bvec = RotationMatrix x yvec
	MatrixOP/FREE/O nvec = RotationMatrix x zvec
	
	/// q Matrix and solidangle correction matrix
	variable theta_res, q_res, L0//, pmag
	theta_res = atan(U_PixelSize*1E-6/U_SDD) //resolution of scattering angle, radian
	q_res = 4*pi/U_Lambda*sin(theta_res/2) //resolution of the magnitude of scattering vector, A
	L0 = U_SDD*abs(MatrixDot(zvec, nvec))/MatrixDot(nvec,nvec) //formula to get distance from a point to a plane, using the normal vector.
	
	Make/FREE/D/O/N=(U_Xmax+1,U_Ymax+1,3) pvecMap, qvecMap //contains qx, qy, qz, qmag, solid angle correction factor at each layer.
	Make/D/O/N=(U_Xmax+1,U_Ymax+1) qindexMap, SolidAngleCorrMap

	Multithread pvecMap = (p-U_X0)*avec[r]*U_PixelSize*1E-6 + (q-U_Y0)*bvec[r]*U_PixelSize*1E-6 + U_SDD*zvec[r]
	MatrixOP/FREE/O pmagMap = sqrt(pvecMap[][][0]*pvecMap[][][0] + pvecMap[][][1]*pvecMap[][][1] + pvecMap[][][2]*pvecMap[][][2])
	
	Multithread qvecMap = 2*pi/U_Lambda*(pvecMap[p][q][r]/pmagMap[p][q]-zvec[r])
	MatrixOP/FREE/O qmagMap = sqrt(qvecMap[][][0]*qvecMap[][][0] + qvecMap[][][1]*qvecMap[][][1] + qvecMap[][][2]*qvecMap[][][2])
	
	Multithread qindexMap = round(qmagMap/q_res)
	variable qIndex_min = WaveMin(qindexMap)
	Multithread qindexMap -= qIndex_min
	Multithread SolidAngleCorrMap = (pmagMap/L0)^3
	U_qnum = WaveMax(qindexMap) + 1 //qindexMap starts from 0

	make/O/D/N=(U_qnum) qq, theta
	qq = WaveMin(qmagMap) + q_res*p
	theta = 2*asin(qq/4/pi*U_Lambda)
	
End

/// Circular average loop
ThreadSafe Static Function CircularAverage(pWave, df1d)
	Wave pWave
	string df1d
	
	/// Set global variables, which are shared with the other procedures. 
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
		Variable/G U_Xmax, U_Ymax, U_qnum
		NVAR Xmax = U_Xmax
		NVAR Ymax = U_Ymax
		NVAR qnum = U_qnum
		Wave qindexMap
		Wave SolidAngleCorrMap
	
	SetdataFolder saveDFR	
		
   /// Create a refwave to store values. added int and count number.
   	make/FREE/D/O/N=(qnum) refwave, refint, referr, count
	
  	/// Start circular average
   variable i, j, qindex
   count = 0 //initialize count
   
   /// Add pixels to get circular sum
   for(i=0; i<Xmax+1; i++) //gXmax is the coordinates.
    	for (j=0; j<Ymax+1; j++)

    		if(pWave[i][j]<0)
    			//skip add when intensity is negative.
    		else
    			//Get theta of the selected pixel.
    			qindex = qindexMap[i][j] //thetaMap[i][j] contains normalized theta values (Integer) by a minimum theta value deterimined above.
    			// ADD INTENSITY.
	 	  	 	refwave[qindex] += pWave[i][j]*SolidAngleCorrMap[i][j]
	 	  	 	count[qindex] += 1 //calculate the pixel number that corresponds to distance r, considering the mask.
	 	   endif
	 	   
	 	endfor
	 endfor
	 
	/// Calcuate mean
	/// Note that Error at each pixel ERR = sqrt(I).
  	/// The error propagation leads to SUERR = {SUM([sqrt(I)]^2)}^0.5 = {SUM[I]}^0.5.
  	/// So you can simply calcualte the SUM(I) to get the Err.
	refint = refwave/count
	referr = refwave^0.5/count
	
	string newintname = df1d + NameofWave(pWave)
	string newinterrname = df1d + NameofWave(pWave) + "_ERR"
	duplicate/O/D refint $newintname
	duplicate/O/D referr $newinterrname
	
End


