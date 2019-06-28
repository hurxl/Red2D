#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function Binning1D()
	//Select a wave to bin
	String targetName
	Variable numOfbin = 1
	Prompt targetName,"Select a wave to bin.",popup wavelist("*",";","DIMS:1,TEXT:0")
	Prompt numOfbin, "Enter the number of points to bin."	// Set prompt for x param
	Doprompt "1D Binning", targetName, numOfbin
	if (V_Flag)
		Print "Canceled"
		return 0									// user canceled
	endif
	
	if (numOfbin<=0)
		Print "Number of points to bin should be larger than 1."
		Return 0
	Endif
	
	Wave refwave0 = $(targetName)
	Variable dimold = Dimsize(refwave0, 0)
	Variable dimnew = round(dimold/numOfbin)
	
	Make/O/D/N=(dimnew) refwave1
	
	variable i, j
	
	If(StringMatch(NameofWave(refwave0), "*_ERR")) //if string contains _ERR, do error propagation.
	
		For(i=0; i<dimnew; i+=1)
			For(j=0; j<numOfbin; j+=1)
				refwave1[i] += refwave0[i*numOfbin+j]^2
			Endfor
			refwave1[i] = refwave1[i]^0.5/numOfbin
		Endfor
		
	Else //If not, do normal calculation.
	
		For(i=0; i<dimnew; i+=1)
			For(j=0; j<numOfbin; j+=1)
				refwave1[i] += refwave0[i*numOfbin+j]	
			Endfor
			refwave1[i] /= numOfbin
		Endfor
		
	Endif
	
	
	
	Duplicate/O/D refwave1, $(targetName+"_bin")
	Killwaves refwave1
	
	Print "Done."
	
End
