#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function R2D_SANSU_SortImagesBySDD()
	
	R2D_CreateImageList(1)	// create an imagelist
	wave/T imagelist = :Red2Dpackage:imagelist
	variable numOfImages = DimSize(imagelist, 0)
	
	variable i
	string datafoldername
	string SDD, Collimation
	string wavenote
	For(i=0; i<numOfImages; i++)
		Wave target = $imagelist[i]
		wavenote = note(target)
		SDD = StringByKey("2D-PSD Pos.", wavenote, ": ", "\r")
		Collimation = StringByKey("Collimation", wavenote, ": ", "\r")
		datafoldername = "SDD"+SDD+"_Coll"+Collimation
		NewDataFolder/O $datafoldername
		MoveWave target, $(":"+datafoldername+":")
	Endfor
	
End

Function R2D_SANSU_AddNote2Datasheet(Key, KeySeparator, ListSeparator, DatasheetColName)
	String Key
	String KeySeparator
	String ListSeparator
	String DatasheetColName
	
	String Datasheet_Path = GetDatasheetPath()  // get path of the datasheet. if in a wrong datafolder, return an error and abort.
	wave/T/Z datasheet = $Datasheet_Path
	String imagefolder = GetWavesDataFolder(datasheet,1)+":" // get the full path of the datafolder for datasheet

	String imagename
	String imagepath
	String target
	String image_note
	variable numInDatasheet = Dimsize(Datasheet, 0)
	variable i
	
	For(i=0; i<numInDatasheet; i++)
		imagename = Datasheet[i][%ImageName]  // get imagename
		imagepath = imagefolder+imagename  // set image full path. the user may be in the image folder and 1d folder.
		image_note = note($imagepath)  // get note of the image
		target = StringByKey(key, image_note, KeySeparator, ListSeparator)  // get sample name in the note
		Datasheet[i][%$DatasheetColName] = target
	Endfor

End