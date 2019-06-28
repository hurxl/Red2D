#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ShowDatasheet()
	
	DFREF saveDFR = GetDataFolderDFR()
	
	
	//Check if datasheet exist. 0 means no.
	If(DataFolderExists("Datasheet")==0)
		
		//If not, check its parent folder. Useful when 1D folder is selected (happens very often).
		DFREF ParentFolder=$(GetDataFolder(1, saveDFR)+":")
		SetDatafolder ParentFolder
		
		//If not, end the action and print the caution.
		If(DataFolderExists("Datasheet")==0)
			Print "Datasheet folder does not exist. Datasheet will be auto generated when performing circular average."
			SetDataFolder saveDFR
			Return 0
		
		//If exist, show the datasheet
		Else
			SetDataFolder Datasheet
			Wave/T ImageName, SampleName, Trans, Time_s, Th_cm, Temp, Comment1, Comment2
			Edit ImageName, SampleName, Trans, Time_s, Th_cm, Temp, Comment1, Comment2
		Endif
	
	//If exist, show the datasheet
	Else
		SetDataFolder Datasheet
		Wave/T ImageName, SampleName, Trans, Time_s, Th_cm, Temp, Comment1, Comment2
		Edit ImageName, SampleName, Trans, Time_s, Th_cm, Temp, Comment1, Comment2	
	Endif

	SetDataFolder saveDFR
	
End
