/****** Object:  View [dbo].[V_Analysis_Job_Export_MultiAlign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Export_MultiAlign]
AS
SELECT DS.Dataset_ID AS DatasetID, 
    SPath.SP_vol_name_client AS volName, 
    SPath.SP_path AS path, 
    DS.DS_folder_name AS datasetFolder, 
    AJ.AJ_resultsFolderName AS resultsFolder, 
    DS.Dataset_Num AS datasetName, AJ.AJ_jobID AS JobId, 
    DS.DS_LC_column_ID AS ColumnID, 
    ISNULL(DS.Acq_Time_Start, DS.DS_created) AS AcquisitionTime, 
    E.EX_Labelling AS Labelling, 
    InstName.IN_name AS InstrumentName, 
    AJ.AJ_analysisToolID AS ToolID, 
    RR.RDS_Block AS BlockNum, 
    RR.RDS_Name AS ReplicateName, 
    DS.Exp_ID AS ExperimentID, 
    RR.RDS_Run_Order AS RunOrder, 
    RR.RDS_BatchID AS BatchID, 
    DFP.Archive_Folder_Path AS ArchPath, 
    DFP.Dataset_Folder_Path AS DatasetFullPath, 
    Org.OG_name AS Organism, 
    C.Campaign_Num AS Campaign,
    AJ.AJ_parmFileName AS ParameterFileName,
    AJ.AJ_settingsFileName AS SettingsFileName
FROM T_Dataset DS
     INNER JOIN T_Analysis_Job AJ
       ON DS.Dataset_ID = AJ.AJ_datasetID
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN t_storage_path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     LEFT OUTER JOIN T_Requested_Run RR
       ON RR.DatasetID = DS.Dataset_ID
     INNER JOIN V_Dataset_Folder_Paths DFP
       ON DS.Dataset_ID = DFP.Dataset_ID
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
WHERE (AJ.AJ_analysisToolID IN (2, 7, 10, 11, 12, 16, 18, 27)) AND 
      (AJ_StateID = 4)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Export_MultiAlign] TO [DDL_Viewer] AS [dbo]
GO
