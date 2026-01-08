#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Menu "Red2D"

	Submenu "1. Load Images"
		"Load Selected TIFF Images", R2D_LoadImages(".tif", "files", 1)	// files: load selected files, 1: overwrite enabled
		"Load All TIFF Images in Folder", R2D_LoadImages(".tif", "folder", 1)	// folder: load all files in the selected folder, 1: overwrite enabled
		"Load TIFF Recursively", R2D_LoadImages(".tif", "recursive", 1)	// recursive: load all files recursively, 1: overwrite enabled
		"-"
		"Load a SAXSpoint h5z file",  R2D_Load_SAXSpoint_h5z()	// h5z file: load h5z file of AntonPaar SAXSpoint
		"-"

		"Load Selected EDF Images", R2D_LoadImages(".edf", "files", 1)	// files: load selected files, 1: overwrite enabled
		"Load All EDF Images in Folder", R2D_LoadImages(".edf", "folder", 1)	// folder: load all files in selected, 1: overwrite enabled
		"-"
		"Load All Text Images (txt) in Folder", R2D_LoadImages(".txt", "folder", 1)
		"Load All Text Images (asc) in Folder", R2D_LoadImages(".asc", "folder", 1)
		"Load All Text Images (dat) in Folder", R2D_LoadImages(".dat", "folder", 1)
	End
	
	"2. Display Images", R2D_Display2D()
	"3. Fit Standard", R2D_CreStdFitPanel()

	"4. Make Masks", R2D_MaskPanel()
	"5. Circular Average", R2D_CircularAveragePanel()
	
	Submenu "6. Display 1D"
		"Display I vs q", R2D_Display1D(0, "_q")
		"Append I vs q ", R2D_Display1D(1, "_q")
		"Display I vs 2θ ", R2D_Display1D(0, "_2t")
		"Append I vs 2θ", R2D_Display1D(1, "_2t")
//		"Show and Hide Traces", ShowHideTracesPanel()
	End
	
	Submenu "7. Datasheet"
		"Import Datasheet from Excel", R2D_ImportDatasheet()
		"Create New Empty Datasheet", R2D_CreateOrShowDatasheet(0)
		"Append New Waves", R2D_CreateOrShowDatasheet(2)
		"Show Existing Datasheet", R2D_CreateOrShowDatasheet(1)
		"-"
		"Auto Fill Datasheet (SAXSpoint)", R2D_FillDataseetSAXSpoint()
	End
	
	Submenu "8. Normalize 1D"	
		"1. Time and Transmission", R2D_TimeAndTrans1D()
		"2. Subtract Cell or Air", R2D_Cellsubtraction1D()
		"3. Thickness Correction", R2D_ThickCorr1D()
		"4. Absolute Intensity", R2D_AbsoluteNorm1D()
		"5. Subtract Solvent", R2D_SolventSubtraction()
		"-"
		"Load SAXS GC calibration curve (NIST SRM3600)", LoadGC_NIST("SAXS")
		"Load SAXS GC calibration curve (AlfaAesar)", LoadGC_AlfaAesar("SAXS")
		"-"
		"Time only", R2D_Time1D()
		"Transmission only", R2D_Trans1D()
		
	End
	
	Submenu "\\M09. Export/Import 1D"
		"Export 1D (q, ImageName)", R2D_Export1D(0, 0)
		"Export 1D (2t, ImageName)", R2D_Export1D(0, 1)
		"Export 1D (q, SampleName)", R2D_Export1D(1, 0)
		"Export 1D (2t, SampleName)", R2D_Export1D(1, 1)
		"-"
		"Import 1D profiles (q, i, s)", R2D_LoadSelectedQIS()
	End
	
	Submenu "Misc"
		"Auto Process", R2D_AutoProcess_panel()
		"-"
		"Convert Coordinates of 2D Images", R2D_2DImageConverterPanel()
		"Make Masked 2D Images", R2D_MakeMaskedImages()
		"Sensitivity correction 2D", R2D_Sensitivity2D()
		"Convert 32bit integer images to single float (-1 to NaN)", R2D_negative2NaN()
		"Convert NaN to 1E-30", R2D_NaN2en30()
		"-"
		"Create Panorama Image (SAXSpoint)", R2D_SAXSpoint_create_panorama_images()
		"-"
		Submenu "2D Operation"
			"1. Time and Transmission (2D)", R2D_TimeAndTrans2D()
			"2. Subtract Cell or Air (2D)", R2D_Cellsubtraction2D()
			"3. Thicknes Correction (2D)", R2D_ThickCorr2D()
			"4. Absolute Intensity (2D)", AbsoluteNorm2D()
			"5. Subtract Solvent (2D)", R2D_SolventSubtraction2D()
			"-"
			"Time only (2D)" , R2D_Time2D()
			"Trans only (2D)" , R2D_Trans2D()
			"-"
			"Rebuild 2D from 1D", R2D_rebuild2D_panel()
			"Add 2D Images", R2D_Add2DImages(0)
		End
		"-"
		"\\M0Resampling/Binning 1D", R2D_Resample1D()
		"\\M0Shorten 1D (irreversible!)", R2D_Shorten1D()
		"-"
		"SDD Combiner", R2D_SDDCombinerpanel()
		"-"
		"Total count (Accept ROI)", R2d_TotalCount()
		"Get beam center", R2D_GetBeamCenter()
		"-"
		"Simple Circular Average", R2D_CircularAveragePanel_simple()
		"Display I vs p", R2D_Display1D(0,2)
		"Append I vs p", R2D_Display1D(1,2)
		"-"
		
		Submenu "Analysis"
			"Runland Streak Analysis", R2D_RulandStreakAnalysis()
			"Cylinder Simulator", Red2D_Rotate_Rod_panel()
			"-"
			"Make q2 waves", R2D_make_qq()
			"Guinier Plot", R2D_Guinier_plot()
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