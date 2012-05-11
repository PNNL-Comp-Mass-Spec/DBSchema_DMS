/****** Object:  Table [T_Default_SP_Params] ******/
/****** RowCount: 6 ******/
/****** Columns: SP_Name, ParamName, ParamValue, Description ******/
INSERT INTO [T_Default_SP_Params] VALUES ('MakeNewJobsFromAnalysisBroker','bypassDatasetArchive','1','waive the requirement that there be an existing complete dataset archive job in broker')
INSERT INTO [T_Default_SP_Params] VALUES ('MakeNewJobsFromAnalysisBroker','datasetIDFilterMax','0','If non-zero, then will be used to filter the candidate datasets')
INSERT INTO [T_Default_SP_Params] VALUES ('MakeNewJobsFromAnalysisBroker','datasetIDFilterMin','0','If non-zero, then will be used to filter the candidate datasets')
INSERT INTO [T_Default_SP_Params] VALUES ('MakeNewJobsFromAnalysisBroker','importWindowDays','10','Max days to go back in DMS archive table looking for results transfers')
INSERT INTO [T_Default_SP_Params] VALUES ('MakeNewJobsFromAnalysisBroker','loggingEnabled','0','Set to 1 to enable SP logging')
INSERT INTO [T_Default_SP_Params] VALUES ('MakeNewJobsFromAnalysisBroker','timeWindowToRequireExisingDatasetArchiveJob','30','Days')
