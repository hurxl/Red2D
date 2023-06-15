#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Menu "Red2D"

	Submenu "1. Load Images"
		"Load Selected TIFF Images", R2D_LoadImages(".tif", "files", 1)	// files: load selected files, 1: overwrite enabled
		"Load All TIFF Images in Folder", R2D_LoadImages(".tif", "folder", 1)	// folder: load all files in selected, 1: overwrite enabled
		"-"
		"Load Selected EDF Images", R2D_LoadImages(".edf", "files", 1)	// files: load selected files, 1: overwrite enabled
		"Load All EDF Images in Folder", R2D_LoadImages(".edf", "folder", 1)	// folder: load all files in selected, 1: overwrite enabled
		"-"
		"Load All Text Images (txt) in Folder", R2D_LoadImages(".txt", "folder", 1)
		"Load All Text Images (asc) in Folder", R2D_LoadImages(".dat", "folder", 1)
		"Load All Text Images (dat) in Folder", R2D_LoadImages(".asc", "folder", 1)
	End
	
	"2. Display Images", R2D_Display2D()
	"3. Fit Standard", R2D_CreStdFitPanel()

	"4. Make Masks", R2D_MaskPanel()
	"5. Circular Average", R2D_CircularAveragePanel()
	
	Submenu "6. Display 1D"
		"Display I vs q", R2D_Display1D(0, 0)
		"Append I vs q ", R2D_Display1D(1, 0)
		"Display I vs 2θ ", R2D_Display1D(0, 1)
		"Append I vs 2θ", R2D_Display1D(1, 1)
		"\\M0Show/Hide Traces", R2D_ShowHideTraces()
	End
	
	Submenu "7. Datasheet"
		"Import Datasheet from Excel", R2D_ImportDatasheet()
		"Create New Empty Datasheet", R2D_CreateOrShowDatasheet(0)
		"Append New Waves", R2D_CreateOrShowDatasheet(2)
		"Show Existing Datasheet", R2D_CreateOrShowDatasheet(1)
	End
	
	Submenu "8. Normalize 1D"	
		"1. Time and Transmittance", TimeAndTrans1D()
		"2. Subtract Cell or Air", Cellsubtraction1D()
		"3. Thickness Correction", ThickCorr1D()
		"4. Absolute Intensity", AbsoluteNorm()
		"5. Subtract Solvent", SolventSubtraction()
		"-"
		"Load SAXS GC calibration curve (NIST SRM3600)", LoadGC_NIST("SAXS")
		"Load SAXS GC calibration curve (AlfaAesar)", LoadGC_AlfaAesar("SAXS")
	End
	
	Submenu "Misc"
		"Auto Process", R2D_AutoProcess_panel()
		"-"
		"Convert to azimuthal-q coordinates", R2D_Azimuthal2DPanel()
		"Convert 32bit integer images to single float (-1 to NaN)", R2D_negative2NaN()
		"-"
		"Sensitivity correction 2D", R2D_Sensitivity2D()
		"Time and trans correction 2D", R2D_TimeAndTrans2D()
		"Subtract a 2D image", R2D_Cellsubtraction2D()
		"Add 2D Images", R2D_Add2DImages(0)
		"Make Masked 2D Images", R2D_MakeMaskedImages()
		"-"
		"\\M0Logarithmic 1D resampling/binning", R2D_LogResample1D()
		"\\M0Shorten 1D (irreversible!)", R2D_Shorten1D()
		"-"
		"SDD Combiner", R2D_SDDCombineranel()
		"-"
		"Import 1D profiles", R2D_LoadSelectedQIS()
		"Export 1D with ImageName and q", R2D_Export1D(0, 0)
		"Export 1D with ImageName and 2theta", R2D_Export1D(0, 1)
		"Export 1D with SampleName and q", R2D_Export1D(1, 0)
		"Export 1D with SampleName and 2theta", R2D_Export1D(1, 1)
		"-"
		"Total count (Accept ROI)", R2d_TotalCount()
		"Get beam center", R2D_GetBeamCenter()
		"-"
		"Simple Circular Average", R2D_CircularAveragePanel_simple()
		"Display I vs p", R2D_Display1D(0,2)
		"Append I vs p", R2D_Display1D(1,2)
		"-"
		
		Submenu "Analysis"
			R2D_RulandStreakAnalysis_Exist(), R2D_RulandStreakAnalysis()
			R2D_CylinderSimulator_Exist(), Red2D_Rotate_Rod_panel()
		End
		
		"-"
		Submenu "SANSU"
			"Load SANS-U Binary Images (.mdat) From Folder", R2D_LoadImages(".mdat", "folder", 1)
			"Load SANS-U Binary Images (.sdat) From Folder", R2D_LoadImages(".sdat", "folder", 1)
			"Sort Images by collimation and SDD", R2D_SANSU_SortImagesBySDD()
			"Extract Sample Name (only for text image) and Append to Datasheet", R2D_SANSU_AddNote2Datasheet("Sample Name", ": ", "\r", "SampleName")
			"Extract Prest Time (only for text image) and Append to Datasheet", R2D_SANSU_AddNote2Datasheet("Preset Time", ": ", "\r", "Time_s")
			"Load SANS GC calibration curve (NIST SRM3600)", LoadGC_NIST("SANS")
			"Load SANS GC calibration curve (AlfaAesar)", LoadGC_AlfaAesar("SANS")
		End
		
	End

End


Function/S R2D_RulandStreakAnalysis_Exist()

	if(Exists("R2D_RulandStreakAnalysis"))
		return "Ruland Streak Analysis (needs phi vs q image)"
	else
		return ""
	endif

End

Function/S R2D_CylinderSimulator_Exist()

	if(Exists("Red2D_Rotate_Rod_panel"))
		return "Simulate 2D cylinder profile"
	else
		return ""
	endif

End