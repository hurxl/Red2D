#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function SetSDDParameters()
	
	//Set global variables.
	If(DataFolderExists("Red2DPackage")==0)
		NewdataFolder Red2DPackage
	Endif
	
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
		Variable/G V_X0, V_Y0, V_SDD, V_Lambda, V_Pixcelsize, V_peak, V_refpeak
	SetdataFolder saveDFR
	
	//Create a new panel to collect parameter to calculate SDD
	NewPanel/K=1/N=SDDCalculator/W=(200,200,420,400)
	SetVariable setvar0 title="Peak Position [pt]",pos={10,5},size={200,25},limits={0,inf,0.01},fSize=13, value=:Red2DPackage:V_peak
	SetVariable setvar1 title="Pixcel Size [um]",pos={10,30},size={200,25},limits={0,inf,1},fSize=13, value=:Red2DPackage:V_Pixcelsize, help={"Pilatus = 172um, Eiger = 75um"}
	SetVariable setvar2 title="Reference Peak [A-1]",pos={10,55},size={200,25},limits={0,inf,0.001},fSize=13, value=:Red2DPackage:V_refpeak, help={"AgBh(A-1): 1st 0.1076; 2nd 0.2152; 3rd 0.3228"}
	SetVariable setvar3 title="Lambda [A]",pos={10,80},size={200,25},limits={0,inf,0.01},fSize=13, value=:Red2DPackage:V_Lambda
	Button button0 title="Calcualte SDD",size={120,25},pos={50,120},proc=ButtonProcSDD
	Button button1 title="Refresh",size={120,25},pos={50,160},proc=ButtonProcRefreshSDDPanel
	
	//theta = tan(peak_pos*pixcelsize/SDD)
	//refpeak_q=4*pi/lambda*sin(theta/2)
	//SDD=peak_pos*pixcelsize*1E-6/atan(asin(refpeak_q/4/pi*lambda)*2)
	//Pixcelsize should be given in um.
	//refpeak_q and lambda should be given in both nm or both A.
	//SDD is calcualted in m.
	
End

Function ButtonProcSDD(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up

			//Set global variables.
			If(DataFolderExists("Red2DPackage")==0)
				NewdataFolder Red2DPackage
			Endif
	
			DFREF saveDFR = GetDataFolderDFR()
			SetDataFolder Red2DPackage
				Variable/G V_X0, V_Y0, V_SDD, V_Lambda, V_Pixcelsize, V_peak, V_refpeak
				NVAR X0 = V_X0
				NVAR Y0 = V_Y0
				NVAR SDD = V_SDD
				NVAR Lambda = V_Lambda
				NVAR Pixcelsize = V_Pixcelsize
				NVAR peak = V_peak
				NVAR refpeak = V_refpeak
			SetdataFolder saveDFR

			SDD = peak*Pixcelsize*1E-6/tan(asin(refpeak/4/pi*Lambda)*2)
			Print "SDD =", SDD, "m"
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function ButtonProcRefreshSDDPanel(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up

		//Set global variables.
		If(DataFolderExists("Red2DPackage")==0)
				NewdataFolder Red2DPackage
		Endif
	
		DFREF saveDFR = GetDataFolderDFR()
		SetDataFolder Red2DPackage
			Variable/G V_X0, V_Y0, V_SDD, V_Lambda, V_Pixcelsize, V_peak, V_refpeak
		SetdataFolder saveDFR
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End