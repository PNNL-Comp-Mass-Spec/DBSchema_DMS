/****** Object:  Table [T_MiscOptions] ******/
/****** RowCount: 3 ******/
SET IDENTITY_INSERT [T_MiscOptions] ON
INSERT INTO [T_MiscOptions] (ID, Name, [Value], Comment) VALUES (1,'RequestedRunRequireWorkpackage',1,'1 to require a work package for new requested runs; 0 to ignore empty work packages')
INSERT INTO [T_MiscOptions] (ID, Name, [Value], Comment) VALUES (2,'ValidateEUSData',1,'1 to validate EUS information when creating new datasets; 0 to disable the validation')
INSERT INTO [T_MiscOptions] (ID, Name, [Value], Comment) VALUES (3,'ArchiveDisabled',0,'1 if archive operations are disabled; used by V_Datasets_Stale_and_Failed')
SET IDENTITY_INSERT [T_MiscOptions] OFF
