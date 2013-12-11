/****** Object:  Table [T_Step_Tools] ******/
/****** RowCount: 11 ******/
SET IDENTITY_INSERT [T_Step_Tools] ON
INSERT INTO [T_Step_Tools] (ID, Name, Description, Bionet_Required, Only_On_Storage_Server, Instrument_Capacity_Limited, Holdoff_Interval_Minutes, Number_Of_Retries, Processor_Assignment_Applies) VALUES (13,'ArchiveStatusCheck','Verify that MyEMSL has validated the checksums of ingested data, including making sure it has been copied to tape.  This process can take up to 24 hours, thus the long holdoff interval and large number of retries','N','N','N',60,100,'N')
INSERT INTO [T_Step_Tools] (ID, Name, Description, Bionet_Required, Only_On_Storage_Server, Instrument_Capacity_Limited, Holdoff_Interval_Minutes, Number_Of_Retries, Processor_Assignment_Applies) VALUES (3,'ArchiveUpdate','Create specific analysis results folder in dataset folder in archive and copy contents of results folder in storage to it.','N','Y','N',60,10,'N')
INSERT INTO [T_Step_Tools] (ID, Name, Description, Bionet_Required, Only_On_Storage_Server, Instrument_Capacity_Limited, Holdoff_Interval_Minutes, Number_Of_Retries, Processor_Assignment_Applies) VALUES (11,'ArchiveUpdateTest','Test instance of the ArchiveUpdate tool','N','Y','N',1,10,'N')
INSERT INTO [T_Step_Tools] (ID, Name, Description, Bionet_Required, Only_On_Storage_Server, Instrument_Capacity_Limited, Holdoff_Interval_Minutes, Number_Of_Retries, Processor_Assignment_Applies) VALUES (12,'ArchiveVerify','Verify that data was successfully ingested into MyEMSL','N','N','N',5,100,'N')
INSERT INTO [T_Step_Tools] (ID, Name, Description, Bionet_Required, Only_On_Storage_Server, Instrument_Capacity_Limited, Holdoff_Interval_Minutes, Number_Of_Retries, Processor_Assignment_Applies) VALUES (2,'DatasetArchive','Create dataset folder on archive and copy everything from storage dataset folder into it','N','Y','N',60,10,'N')
INSERT INTO [T_Step_Tools] (ID, Name, Description, Bionet_Required, Only_On_Storage_Server, Instrument_Capacity_Limited, Holdoff_Interval_Minutes, Number_Of_Retries, Processor_Assignment_Applies) VALUES (1,'DatasetCapture','Create dataset folder on storage server and copy instrument data into it','Y','N','Y',0,0,'Y')
INSERT INTO [T_Step_Tools] (ID, Name, Description, Bionet_Required, Only_On_Storage_Server, Instrument_Capacity_Limited, Holdoff_Interval_Minutes, Number_Of_Retries, Processor_Assignment_Applies) VALUES (4,'DatasetInfo','Look at raw data files in storage and extract descriptive information','N','N','N',0,0,'N')
INSERT INTO [T_Step_Tools] (ID, Name, Description, Bionet_Required, Only_On_Storage_Server, Instrument_Capacity_Limited, Holdoff_Interval_Minutes, Number_Of_Retries, Processor_Assignment_Applies) VALUES (8,'DatasetIntegrity','Make sure that raw data is not corrupted','N','N','N',0,0,'N')
INSERT INTO [T_Step_Tools] (ID, Name, Description, Bionet_Required, Only_On_Storage_Server, Instrument_Capacity_Limited, Holdoff_Interval_Minutes, Number_Of_Retries, Processor_Assignment_Applies) VALUES (9,'DatasetQuality','Decide whether or not dataset can be automatically dispositioned as released, or needs to be looked at by person','N','N','N',0,0,'N')
INSERT INTO [T_Step_Tools] (ID, Name, Description, Bionet_Required, Only_On_Storage_Server, Instrument_Capacity_Limited, Holdoff_Interval_Minutes, Number_Of_Retries, Processor_Assignment_Applies) VALUES (10,'ImsDeMultiplex','DeMux IMS data','N','N','N',5,4,'N')
INSERT INTO [T_Step_Tools] (ID, Name, Description, Bionet_Required, Only_On_Storage_Server, Instrument_Capacity_Limited, Holdoff_Interval_Minutes, Number_Of_Retries, Processor_Assignment_Applies) VALUES (5,'SourceFileRename','Put "x_" prefix on source files in instrument xfer directory','Y','N','N',120,24,'N')
SET IDENTITY_INSERT [T_Step_Tools] OFF
