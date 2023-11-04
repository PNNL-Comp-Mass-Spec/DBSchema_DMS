/****** Object:  Table [T_Automatic_Jobs] ******/
/****** RowCount: 4 ******/
/****** Columns: Script_For_Completed_Job, Script_For_New_Job, Enabled ******/
INSERT INTO [T_Automatic_Jobs] VALUES ('DatasetArchive','MyEMSLVerify',1)
INSERT INTO [T_Automatic_Jobs] VALUES ('DatasetArchive','SourceFileRename',1)
INSERT INTO [T_Automatic_Jobs] VALUES ('DatasetCapture','LCDatasetCapture',0)
INSERT INTO [T_Automatic_Jobs] VALUES ('LCDatasetCapture','ArchiveUpdate',1)
