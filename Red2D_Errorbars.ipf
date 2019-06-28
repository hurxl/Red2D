#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Display 1D use this function.
Function/S AddErrRed2D(reflist)
	String reflist
	
	Print reflist
	Variable NumOfTraces = ItemsinList(reflist,";")
	
	Variable i
	String ref, ref_err
	For(i=0; i<NumOfTraces; i++)
		
		// Use string reference because errorbars and the other modify graph command deal with traces but not waves.
		ref = StringFromList(i, reflist)
		ref_err = StringFromList(i, reflist)+"_err"	
		
		If (waveexists($(ref)) == 1)
			ErrorBars $(ref) SHADE= {0,0,(0,0,0,0),(0,0,0,0)},wave=($(ref_err),$(ref_err)) // Append errorbars to traces.
			Print "Plotted " + ref+" with "+ ref_err
		Else
			Print ref + " or " + ref_err + " does not exist in current data folder." 
		endif
		
	Endfor

End

Function AddAllErrRed2D()
	String traces = TraceNameList("",";",3) // Get traces name list of top graph
	Variable NumOfTraces = itemsinlist(traces,";") // Get number of traces
	Variable i
	
	For(i=0; i<NumOfTraces; i+=1)
	
		silent 1 // delay display update
		pauseupdate // delay display update
		
		// Use string reference because errorbars and the other modify graph command deal with traces but not waves.
		String ref = StringFromList(i, traces)
		String ref_err = StringFromList(i, traces)+"_err"
		
		Wave wref = $(ref)
		Wave wref_err = $(ref_err)
		If (waveexists(wref) == 1)
			ErrorBars wref SHADE= {0,0,(0,0,0,0),(0,0,0,0)},wave=(wref_err,wref_err) // Append errorbars to traces.
		endif
		
	Endfor
	
End

Function RemoveAllErrRed2D()
	String traces = TraceNameList("",";",3) // Get traces name list of top graph
	Variable NumOfTraces = itemsinlist(traces,";") // Get number of traces
	Variable i
	
	For(i=0; i<NumOfTraces; i+=1)
	
		silent 1 // delay display update
		pauseupdate // delay display update
	
		// Use string reference because errorbars and the other modify graph command deal with traces but not waves.
		String ref = StringFromList(i, traces)
		
		ErrorBars $(ref) OFF // Append errorbars to traces.
		
	Endfor
	Return 0
End