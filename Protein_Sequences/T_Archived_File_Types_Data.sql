/****** Object:  Table [T_Archived_File_Types] ******/
/****** RowCount: 2 ******/
SET IDENTITY_INSERT [T_Archived_File_Types] ON
INSERT INTO [T_Archived_File_Types] (Archived_File_Type_ID, File_Type_Name, Description) VALUES (1,'static','Static collection, listed in T_Protein_Collections')
INSERT INTO [T_Archived_File_Types] (Archived_File_Type_ID, File_Type_Name, Description) VALUES (2,'dynamic','Transient, runtime generated collection, not listed in T_Protein_Collections')
SET IDENTITY_INSERT [T_Archived_File_Types] OFF
