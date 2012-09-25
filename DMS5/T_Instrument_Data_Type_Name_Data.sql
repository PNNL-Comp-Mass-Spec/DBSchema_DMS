/****** Object:  Table [T_Instrument_Data_Type_Name] ******/
/****** RowCount: 14 ******/
SET IDENTITY_INSERT [T_Instrument_Data_Type_Name] ON
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension, Comment) VALUES (1,'dot_raw_files',0,'.Raw','')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension, Comment) VALUES (2,'dot_wiff_files',0,'.Wiff','')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension, Comment) VALUES (3,'dot_uimf_files',0,'.UIMF','')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension, Comment) VALUES (4,'zipped_s_folders',1,'','')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension, Comment) VALUES (5,'biospec_folder',1,'','')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension, Comment) VALUES (6,'dot_raw_folder',1,'','')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension, Comment) VALUES (7,'dot_d_folders',1,'','')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension, Comment) VALUES (8,'bruker_ft',1,'','.D folder that has a .BAF files and ser file')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension, Comment) VALUES (9,'bruker_maldi_spot',1,'','Folder has a .EMF file and a single sub-folder that has an acque file and fid file')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension, Comment) VALUES (10,'bruker_maldi_imaging',1,'','Dataset folder has a series of zip files with names like 0_R00X329.zip; each .Zip file has a series of subfolders with names like 0_R00X329Y309')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension, Comment) VALUES (11,'sciex_wiff_files',0,'.Wiff','Each dataset has a .wiff file and a .wiff.scan file')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension, Comment) VALUES (12,'bruker_tof_baf',1,' ','.D folder from Maxis instrument')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension, Comment) VALUES (13,'data_folders',1,'','Used for miscellaneous data files')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension, Comment) VALUES (15,'dot_mzml_files',0,'.mzML','.mzML file')
SET IDENTITY_INSERT [T_Instrument_Data_Type_Name] OFF
