#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Red2D"

	"1. Load Images", Red2D_Load2D()
	"2. Display Images [P]", Red2D_Display2D(0)
	"3. Fit AgBh [P]", Red2D_CreAgBhPanel(0)
	
	Submenu "4. Mask Images"
		"Sector Mask [P]", Red2D_SectorMaskPanel(0)
		"ROI Mask [P]", Red2D_ROIMaskPanel(0)
	End
	
	"5. Circular Average [P]", Red2D_CircularAveragePanel(0)
	
	Submenu "6. Display 1D"
		"Display 1D", Display1D()
		"Append 1D", Append1D()
		"Quick append Errorbars", AddAllErrRed2D()
		"Quick remove Errorbars", RemoveAllErrRed2D()
		"Show or Hide Traces [P]", ShowHideTraces()
	End
	
	Submenu "7. Normalize 1D"	
		"1. Import Datasheet from Excel", Red2D_ImportDatasheet()
		"2. Time and Transmittance",TimeAndTrans()
		"3. Subtract Cell",Cellsubtraction()
		"4. Thickness Correction",ThickCorr()
		"5. Absolute Intensity",AbsoluteNorm()
		"6. Subtract Solvent", SolventSubtraction()
		"Manually Edit Datasheet", Red2D_CreUpdDatasheet()
	End
	
	Submenu "Others"
		"Load GC calibration curve", LoadGC_NIST()
		"Add 2D Images [P]", Add2DImages()
		"Azimuthal Plot [P]", Red2D_AzimuthalPlotPanel()
		"Binning 1D", Binning1D()
		//"Get BeamCenter By Cursors", GetBeamCenter()
		//"Calculate SDD [P]", SetSDDParameters()
	End
End