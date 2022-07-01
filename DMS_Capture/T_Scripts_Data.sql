/****** Object:  Table [T_Scripts] ******/
/****** RowCount: 11 ******/
SET IDENTITY_INSERT [T_Scripts] ON
INSERT INTO [T_Scripts] (ID, Script, Description, Enabled, Results_Tag, Contents) VALUES (1,'DatasetCapture','This script is for basic dataset capture','Y','CAP','<JobScript Name="DatasetCapture"><Step Number="1" Tool="DatasetCapture" /><Step Number="2" Tool="DatasetIntegrity"><Depends_On Step_Number="1" /></Step><Step Number="3" Tool="DatasetInfo"><Depends_On Step_Number="2" /></Step><Step Number="4" Tool="DatasetQuality"><Depends_On Step_Number="3" /></Step></JobScript>')
INSERT INTO [T_Scripts] (ID, Script, Description, Enabled, Results_Tag, Contents) VALUES (2,'ArchiveUpdate','This script is for updating analysis results folders to archive','Y','UPD','<JobScript Name="ArchiveUpdate"><Step Number="1" Tool="ArchiveUpdate" /><Step Number="2" Tool="ArchiveVerify"><Depends_On Step_Number="1" /></Step><Step Number="3" Tool="ArchiveStatusCheck"><Depends_On Step_Number="2" /></Step></JobScript>')
INSERT INTO [T_Scripts] (ID, Script, Description, Enabled, Results_Tag, Contents) VALUES (3,'DatasetArchive','This script is for initial archive of dataset','Y','DSA','<JobScript Name="DatasetArchive"><Step Number="1" Tool="DatasetArchive" /><Step Number="2" Tool="ArchiveVerify"><Depends_On Step_Number="1" /></Step></JobScript>')
INSERT INTO [T_Scripts] (ID, Script, Description, Enabled, Results_Tag, Contents) VALUES (4,'SourceFileRename','This script is for renaming the source file or folder on the instrument','Y','SFR','<JobScript Name="SourceFileRename"><Step Number="1" Tool="SourceFileRename" /></JobScript>')
INSERT INTO [T_Scripts] (ID, Script, Description, Enabled, Results_Tag, Contents) VALUES (5,'HPLCSequenceCapture','This script is for capture of HPLC sequence files','N','CAP','<JobScript Name="HPLCSequenceCapture"><Step Number="1" Tool="DatasetCapture" /></JobScript>')
INSERT INTO [T_Scripts] (ID, Script, Description, Enabled, Results_Tag, Contents) VALUES (6,'IMSDatasetCapture','This script is for IMS dataset capture','Y','CPI','<JobScript Name="IMSDatasetCapture"><Step Number="1" Tool="DatasetCapture" /><Step Number="2" Tool="DatasetIntegrity"><Depends_On Step_Number="1" /></Step><Step Number="3" Tool="ImsDeMultiplex"><Depends_On Step_Number="2" /></Step><Step Number="4" Tool="DatasetInfo"><Depends_On Step_Number="2" /><Depends_On Step_Number="3" /></Step><Step Number="5" Tool="DatasetQuality"><Depends_On Step_Number="4" /></Step></JobScript>')
INSERT INTO [T_Scripts] (ID, Script, Description, Enabled, Results_Tag, Contents) VALUES (7,'IMSDemultiplex','This script is for re-running the Demultiplexing tool on IMS datasets','Y','DMX','<JobScript Name="IMSDemultiplex"><Step Number="1" Tool="ImsDeMultiplex" /></JobScript>')
INSERT INTO [T_Scripts] (ID, Script, Description, Enabled, Results_Tag, Contents) VALUES (8,'Quameter','This script is for running the Quameter tool on datasets','Y','QUA','<JobScript Name="Quameter"><Step Number="1" Tool="DatasetQuality" /></JobScript>')
INSERT INTO [T_Scripts] (ID, Script, Description, Enabled, Results_Tag, Contents) VALUES (9,'MyEMSLDatasetPush','This script pushes a dataset into MyEMSL; it does not push in subfolders','Y','PSH','<JobScript Name="MyEMSLDatasetPush"><Step Number="1" Tool="ArchiveUpdate" /><Step Number="2" Tool="ArchiveVerify"><Depends_On Step_Number="1" /></Step><Step Number="3" Tool="ArchiveStatusCheck"><Depends_On Step_Number="2" /></Step></JobScript>')
INSERT INTO [T_Scripts] (ID, Script, Description, Enabled, Results_Tag, Contents) VALUES (10,'MyEMSLDatasetPushRecursive','This script pushes a dataset, plus all of its subfolders, into MyEMSL','Y','PSH','<JobScript Name="MyEMSLDatasetPushRecursive"><Step Number="1" Tool="ArchiveUpdate" /><Step Number="2" Tool="ArchiveVerify"><Depends_On Step_Number="1" /></Step><Step Number="3" Tool="ArchiveStatusCheck"><Depends_On Step_Number="2" /></Step></JobScript>')
INSERT INTO [T_Scripts] (ID, Script, Description, Enabled, Results_Tag, Contents) VALUES (12,'MyEMSLVerify','This script runs the ArchiveStatusCheck tool to make sure that MyEMSL has validated the checksums of ingested data, including making sure it has been copied to tape.','Y','DSV','<JobScript Name="MyEMSLVerify"><Step Number="1" Tool="ArchiveStatusCheck" /></JobScript>')
SET IDENTITY_INSERT [T_Scripts] OFF
