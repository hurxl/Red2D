#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function Display1D()
	//Get Wave name list of intensity waves
	String preIntList = WaveList("!*_ERR", ";","DIMS:1,TEXT:0") // remove _ERR
	String IntList = RemoveFromList("qq;theta",preIntList ) // remove qq theta
	Variable numOfitems = itemsinlist(IntList)
	wave qq
	
	PauseUpdate
	
	//Display int vs qq
	String ImageName = StringFromList(0, IntList) //Get ImageName (trace name)
	Display $(ImageName) vs qq //Display
	Label left "\\f02I\\f00 [-]"
	Label bottom "\\f02q\\f00 [Å\\S−1\\M]"
	
	//AppendToGraph
	variable i
	For(i=1;i<numOfitems; i++)
		ImageName = StringFromList(i, IntList)
		AppendToGraph $(ImageName) vs qq
	Endfor
	
	Legend/C/F=0/B=1/N=text0 ""
	ModifyGraph log = 1, tick=2,mirror=1,axThick=1.5
	
	AddErrRed2D(IntList) //Add error bars on the traces. May cause error message when error bars wave not exist.
	
End

Function Append1D()
	//Get Wave name list of intensity waves
	String preIntList = WaveList("!*_ERR", ";","DIMS:1,TEXT:0") // remove _ERR
	String IntList = RemoveFromList("qq;theta",preIntList ) // remove qq theta
	Variable numOfitems = itemsinlist(IntList)
	wave qq
	
	String ImageName
	
	PauseUpdate
	
	//AppendToGraph
	variable i
	For(i=0;i<numOfitems; i++)
		ImageName = StringFromList(i, IntList)
		AppendToGraph $(ImageName) vs qq
	Endfor
	
	AddErrRed2D(IntList) //Add error bars on the traces. May cause error message when error bars wave not exist.
	
End