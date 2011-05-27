/****** Object:  Table [T_File_Attachment] ******/
/****** RowCount: 3 ******/
SET IDENTITY_INSERT [T_File_Attachment] ON
INSERT INTO [T_File_Attachment] (ID, File_Name, Description, Entity_Type, Entity_ID, Owner_PRN, File_Size_Bytes, Created, Last_Affected, Archive_Folder_Path, File_Mime_Type) VALUES (1,'one.txt','This is for a software test','lc_cart_config_history','1','D3J410','2.7','4/21/2011 2:54:22 PM','4/21/2011 2:54:22 PM','lc_cart_config/2011/1','')
INSERT INTO [T_File_Attachment] (ID, File_Name, Description, Entity_Type, Entity_ID, Owner_PRN, File_Size_Bytes, Created, Last_Affected, Archive_Folder_Path, File_Mime_Type) VALUES (2,'test.pdf','This is also for testing software','lc_cart_config_history','1','D3J410','342.25','5/4/2011 12:17:43 PM','5/4/2011 12:17:43 PM','lc_cart_config/2011/1','')
INSERT INTO [T_File_Attachment] (ID, File_Name, Description, Entity_Type, Entity_ID, Owner_PRN, File_Size_Bytes, Created, Last_Affected, Archive_Folder_Path, File_Mime_Type) VALUES (3,'043011.pdf','tunerpt','instrument_config_history','1652','fill570','414.33','5/6/2011 12:40:59 PM','5/6/2011 12:40:59 PM','instrument_config/2011/1652','')
SET IDENTITY_INSERT [T_File_Attachment] OFF
