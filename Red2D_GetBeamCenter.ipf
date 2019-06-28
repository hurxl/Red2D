#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function GetBeamCenterPanel()

	String reflist = wavelist("*",";","DIMS:2") //Get wavelist from current folder limited for 2D waves
	Wave/T reftw = ListToTextWave(reflist,";") // Create a text wave reference containing reflist
	Variable NumInList = itemsinlist(reflist) // Get number of items in List

	If(DatafolderExists("Red2DPackage")==0)
		NewDataFolder :Red2DPackage
	Endif

	Duplicate/T/O reftw, :Red2DPackage:W_ImagesList
	
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
		Variable/G V_Xmax, V_Ymax, V_X0, V_Y0, V_SDD, V_Lambda, V_Pixcelsize, V_tiltX, V_tiltY, V_tiltZ // V_tiltZ is not in use. It is actuall X2. I use X-Y-X type rotation.
		NVAR Xmax = V_Xmax
		NVAR Ymax = V_Ymax
	SetdataFolder saveDFR
	
	Wave TopImage = $(reftw[0]) // $()convert string to a wave reference
	Xmax=Dimsize(TopImage,0)-1 //Get image size. Minus 1 because Dimsize is size while Xmax means the coordinates.
	Ymax=Dimsize(TopImage,1)-1 //Get image size
	
	//Create a new panel to collect parameter to perform circular average
	NewPanel/K=1/N=GetBeamCenter/W=(200,200,400,360)
	
	SetVariable setvar1 title="Tilt_X [º]",pos={10,10},size={180,25},limits={-90,90,1},fSize=13, value=:Red2DPackage:V_tiltX, help={"-90 to 90º"}
	SetVariable setvar2 title="Tilt_Y [º]",pos={10,35},size={180,25},limits={-90,90,1},fSize=13, value=:Red2DPackage:V_tiltY, help={"-90 to 90º"}
	Button button0 title="Get Beam Center",size={120,25},pos={45,70},proc=ButtonProcCA //NOT Complete yet
	Button button1 title="Refresh",size={120,25},pos={45,110},proc=ButtonProcRefreshListCA //NOT Complete yet
	
End

Function GetBeamCenter()
	
	//Check if the CDF is at the right position.
	If(Red2Dimagelistexist() == -1)
		return -1
	Endif
	
	If(DatafolderExists("Red2DPackage")==0)
		NewDataFolder :Red2DPackage
	Endif

	String NameOfImageWin = WinName(0,1) //Get the name of top graph window
	Dowindow/F $(NameOfImageWin) //Activate the top graph window
	String TopImageName = ImageNameList("",";")
	TopImageName = StringFromList(0, TopImageName,";")
	TopImageName = ReplaceString("'", TopImageName, "") //delete 'name' from the name. Otherwise igor does not function.
	Wave TopImage = $TopImageName
	
	// Record cursor position into 2 waves
	Make/O CursorX, CursorY
	string csrnamelist = "A;B;C;D;E;F;G;H;I;"
	string csrname
	variable i = 0
	For(i=0;i<9;i++)
		csrname = StringFromList(i,csrnamelist)
		If(strlen(CsrInfo($csrname))==0)
			break
			Print "break"
		Else
			CursorX[i]=xcsr($csrname)
			CursorY[i]=vcsr($csrname)
		Endif
	Endfor
	
	If(i==0)
		DoAlert 0, "No cursor on top image."
	Else
		Print i
		Redimension/N=(i) CursorX, CursorY
	Endif
	
	// Get initial guess
	Variable a = 200
	Variable X0_ini = mean(CursorX)
	Variable Y0_ini = mean(CursorY)
	
	// Dofit
	Duplicate/O CursorX, CursorXFit, CursorYFit
	Make/D/O CircleCoefs={a,X0_ini,Y0_ini} // a, x0, y0
	FuncFit/ODR=3 Tilt, CircleCoefs /X={CursorX, CursorY} /XD={CursorXFit,CursorYFit}

	//Set global variables
	Variable/G :Red2DPackage:V_X0, :Red2DPackage:V_Y0, :Red2DPackage:V_Xmax, :Red2DPackage:V_Ymax, :Red2DPackage:V_aa,  :Red2DPackage:V_bb
	NVAR aa = :Red2DPackage:V_aa
	NVAR bb = :Red2DPackage:V_bb
	NVAR X0 = :Red2DPackage:V_X0
	NVAR Y0 = :Red2DPackage:V_Y0
	NVAR Xmax = :Red2DPackage:V_Xmax
	NVAR Ymax = :Red2DPackage:V_Ymax

	//Input X0 and Y0
	aa = CircleCoefs[0]
	X0 = CircleCoefs[1]
	Y0 = CircleCoefs[2]
	
	// Display center
	Variable X0_fit=round(CircleCoefs[1])
	Variable Y0_fit=round(CircleCoefs[2])

	Cursor/I J $TopImageName X0_fit, Y0_fit
	
	//Get Xmax and Ymax
	Xmax = DimSize(TopImage, 0) - 1 //Minus 1 because the  DimSize gives the number of point, but X0 is the coordinate.
	Ymax = DimSize(TopImage, 1) - 1
	
	//Delete unnecessary coefficient waves
	Wave M_Jacobian, W_sigma
	KillWaves M_Jacobian, W_sigma, CursorX, CursorY, CursorXFit, CursorYFit, CircleCoefs

End

Function Circle(w,x,y) : FitFunc
	Wave w
	Variable x
	Variable y
	//CurveFitDialog/
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = a
	//CurveFitDialog/ w[1] = x0
	//CurveFitDialog/ w[2] = y0
	return ((x-w[1])/w[0])^2 + ((y-w[2])/w[0])^2 - 1
End

Function Tilt(w,x,y) : FitFunc
	Wave w
	Variable x
	Variable y
	//CurveFitDialog/
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = aa
	//CurveFitDialog/ w[1] = x0
	//CurveFitDialog/ w[2] = y0
	variable SDD, ta, sa, rr, bb, mm, nn, ll, ss, pixelsize, lambda, qpeak
	qpeak = 0.1076
	pixelsize = 172e-6
	lambda = 1.0
	sa = 2*asin(qpeak/(4*pi)*lambda)
	ta = 0/180*pi
	SDD = 4*w[0]/sin(sa)*cos(ta)*cos(sa)
	mm = SDD*sin(sa)*(tan(sa+ta) + 1/tan(sa))
	nn = 2*w[0]
	ll = SDD*sin(sa)*(-tan(abs(ta-sa)) + 1/tan(sa))
	ss = 0.5*mm*ll*sin(2*sa)
	rr = 2*ss/(nn+mm+ll)
	bb = sqrt(abs(w[0]^2 - (rr*tan(ta)-SDD*sin(sa)/cos(ta-sa)+w[0])^2))
	
	return ((x-w[1])/(w[0]/pixelsize))^2 + ((y-w[2])/(bb/pixelsize))^2 - 1
End