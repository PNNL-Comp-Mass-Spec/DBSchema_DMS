/****** Object:  Table [T_Instrument_Data_Type_Name] ******/
/****** RowCount: 9 ******/
SET IDENTITY_INSERT [T_Instrument_Data_Type_Name] ON
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension) VALUES (1,'dot_raw_files',0,'.Raw')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension) VALUES (2,'dot_wiff_files',0,'.Wiff')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension) VALUES (3,'dot_uimf_files',0,'.UIMF')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension) VALUES (4,'zipped_s_folders',1,'')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension) VALUES (5,'biospec_folder',1,'')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension) VALUES (6,'dot_raw_folder',1,'')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension) VALUES (7,'dot_d_folders',1,'')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension) VALUES (8,'bruker_ft',1,'')
INSERT INTO [T_Instrument_Data_Type_Name] (Raw_Data_Type_ID, Raw_Data_Type_Name, Is_Folder, Required_File_Extension) VALUES (9,'bruker_tof',1,'')
SET IDENTITY_INSERT [T_Instrument_Data_Type_Name] OFF
