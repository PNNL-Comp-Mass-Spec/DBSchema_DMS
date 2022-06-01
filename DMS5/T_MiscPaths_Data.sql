/****** Object:  Table [T_MiscPaths] ******/
/****** RowCount: 10 ******/
SET IDENTITY_INSERT [T_MiscPaths] ON
INSERT INTO [T_MiscPaths] (path_id, [Function], Server, Client, Comment) VALUES (1,'AnalysisXfer                    ','na','DMS3_Xfer\','')
INSERT INTO [T_MiscPaths] (path_id, [Function], Server, Client, Comment) VALUES (3,'InstrumentSourceScanDir         ','G:\DMS_InstSourceDirScans\','','')
INSERT INTO [T_MiscPaths] (path_id, [Function], Server, Client, Comment) VALUES (4,'LCCartConfigDocs                ','','http://gigasax/LC_Cart_Config/','')
INSERT INTO [T_MiscPaths] (path_id, [Function], Server, Client, Comment) VALUES (5,'DIMTriggerFileDir               ','G:\DIM_Trigger\','','')
INSERT INTO [T_MiscPaths] (path_id, [Function], Server, Client, Comment) VALUES (6,'Database Backup Path            ','\\proto-8\DB_Backups\Gigasax_Backup\','\\proto-8\DB_Backups\Gigasax_Backup\','')
INSERT INTO [T_MiscPaths] (path_id, [Function], Server, Client, Comment) VALUES (8,'Database Backup Log Path        ','G:\SqlServerBackup\','G:\SqlServerBackup\','')
INSERT INTO [T_MiscPaths] (path_id, [Function], Server, Client, Comment) VALUES (9,'Redgate Backup Transfer Folder  ','','','')
INSERT INTO [T_MiscPaths] (path_id, [Function], Server, Client, Comment) VALUES (10,'DMSOrganismFiles                ','\\gigasax\DMS_Organism_Files\','F:\DMS_Organism_Files\','')
INSERT INTO [T_MiscPaths] (path_id, [Function], Server, Client, Comment) VALUES (11,'DMSParameterFiles               ','\\gigasax\DMS_Parameter_Files\','F:\DMS_Parameter_Files\','The specific folder for each step tool is defiend in table AJT_parmFileStoragePath in DMS5 and in table T_Step_Tools in the DMS_Pipeline database')
INSERT INTO [T_MiscPaths] (path_id, [Function], Server, Client, Comment) VALUES (12,'Email_alert_admins              ','EMSL-Prism.Users.DMS_Monitoring_Admins@pnnl.gov','n/a','Used by PostEmailAlert')
SET IDENTITY_INSERT [T_MiscPaths] OFF
