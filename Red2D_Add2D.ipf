#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function Add2DImages()
	
	If(DatafolderExists("Red2DPackage")==0)
		NewDataFolder Red2DPackage
	Endif
	
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder Red2DPackage
	String/G U_StrToMatch, U_NewWaveName
	Variable/G U_NumToCombine
	Make/T/O/N=0 MatchedWaves // Create an empty text wave for listbox to refer
	SetDataFolder saveDFR
	
	//Create a new panel to collect parameters
	NewPanel/K=1/N=Add2D/W=(200,200,900,510)

	SetVariable setvar1 title="String to Match", pos={10,40},size={300,25}, fSize=13, value=U_StrToMatch, help={"Use * as a wildcard. e.g. *test"} //Set match string
	Button button0 title="Show list",size={120,30},pos={100,75},proc=ButtonProcShowList // Activate showlist script
	ListBox lbCW listWave=MatchedWaves, mode=0, size={350,270}, pos={330,10}, fSize=13, userColumnResize=1 // Make a listbox on the panel
	
	//Set parameters and trigger image combine script.
	SetVariable setvar2 title="Number of Images to combine",pos={10,135},size={300,25},limits={1,inf,1},fSize=13, value=U_NumToCombine // Set number of waves to combine
	SetVariable setvar3 title="NewWaveName", pos={10,165},size={300,25}, fSize=13, value=U_NewWaveName //Set match string
	Button button1 title="Add Waves",size={120,30},pos={100,200},proc=ButtonProcCombineWaves // Trigger combine waves script

End

Function ButtonProcShowList(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
		
			SVAR StrToMatch = :Red2DPackage:U_StrToMatch	
			String reflist = wavelist(StrToMatch,";","DIMS:2") //Get wavelist from current folder with matching string and selected dimensions.
			Variable NumInList = itemsinlist(reflist) // Get number of items in List	

			Make/T/O/N=(NumInList) :Red2DPackage:MatchedWaves
			Wave/T MatchedWaves = :Red2DPackage:MatchedWaves
	
			If(NumInList==0)	
				Print "No wave matches your selection."
				Return 0
			Else
					
				variable i
				For(i=0;i<NumInList;i+=1)
					MatchedWaves[i] = StringFromList(i,reflist)
				Endfor
					
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

			For(i=0;i+NumToCombine <= NumOfWaves; i+=NumToCombine) // Count up initiation number
				k=0 // number of the for top loops
				combinedwave = 0 // Initiate combined wave
				
				For(j=0;j<NumToCombine;j+=1) // Count up the iteritation number
					wave refwave = $(MatchedWaves[i+j])
					combinedwave += refwave // Add refwave to the combined wave
				Endfor
				
				/// Create name of the combined wave.
				If(NumToCombine == NumOfWaves)
					Duplicate/O combinedwave, $(AddedDF+NewWaveName) // If add all the images, do not add sequential number.
				Else
					Duplicate/O combinedwave, $(AddedDF+NewWaveName+"_"+Num2str(k))	
				Endif
				k += 1
				
			Endfor
			
			Killwaves combinedwave
			Print "Add Success"
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End