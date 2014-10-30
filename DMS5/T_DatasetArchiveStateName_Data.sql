/****** Object:  Table [T_DatasetArchiveStateName] ******/
/****** RowCount: 16 ******/
/****** Columns: DASN_StateID, DASN_StateName, Comment ******/
INSERT INTO [T_DatasetArchiveStateName] VALUES (0,'(na)','State is unknown')
INSERT INTO [T_DatasetArchiveStateName] VALUES (1,'new','Dataset needs to be archived')
INSERT INTO [T_DatasetArchiveStateName] VALUES (2,'Archive In Progress','Initial dataset archive is in progress')
INSERT INTO [T_DatasetArchiveStateName] VALUES (3,'complete','Dataset folder exists; may or may not contain the instrument data')
INSERT INTO [T_DatasetArchiveStateName] VALUES (4,'purged','Instrument data and all results are purged')
INSERT INTO [T_DatasetArchiveStateName] VALUES (5,'deleted','No longer used: Dataset has been deleted from the archive')
INSERT INTO [T_DatasetArchiveStateName] VALUES (6,'Operation Failed','Operation failed')
INSERT INTO [T_DatasetArchiveStateName] VALUES (7,'Purge In Progress','Dataset purge is in progress')
INSERT INTO [T_DatasetArchiveStateName] VALUES (8,'Purge Failed','Dataset purge failed')
INSERT INTO [T_DatasetArchiveStateName] VALUES (9,'Holding','Dataste archive / purge is on hold')
INSERT INTO [T_DatasetArchiveStateName] VALUES (10,'NonPurgeable','Dataset is not purgeable')
INSERT INTO [T_DatasetArchiveStateName] VALUES (11,'Verification Required','No longer used')
INSERT INTO [T_DatasetArchiveStateName] VALUES (12,'Verification In Progress','No longer used')
INSERT INTO [T_DatasetArchiveStateName] VALUES (13,'Verification Failed','No longer used')
INSERT INTO [T_DatasetArchiveStateName] VALUES (14,'Purged Instrument Data (plus auto-purge)','Corresponds to Purge_Policy=0 (purge instrument data plus any auto-purge items)')
INSERT INTO [T_DatasetArchiveStateName] VALUES (15,'Purged all data except QC folder','Corresponds to Purge_Policy=1 (purge all except QC folder)')
