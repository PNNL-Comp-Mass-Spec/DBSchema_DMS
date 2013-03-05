/****** Object:  Table [T_Archived_File_States] ******/
/****** RowCount: 3 ******/
SET IDENTITY_INSERT [T_Archived_File_States] ON
INSERT INTO [T_Archived_File_States] (Archived_File_State_ID, Archived_File_State, Description) VALUES (1,'original','Collection archived as it existed when uploaded to the database')
INSERT INTO [T_Archived_File_States] (Archived_File_State_ID, Archived_File_State, Description) VALUES (2,'modified','Collection differs from originally loaded collection')
INSERT INTO [T_Archived_File_States] (Archived_File_State_ID, Archived_File_State, Description) VALUES (3,'Inactive','Collection is inactive; do not use')
SET IDENTITY_INSERT [T_Archived_File_States] OFF
