/****** Object:  View [dbo].[V_DMS_Data_Package_Aggregation_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DMS_Data_Package_Aggregation_Datasets]
AS
SELECT TPD.Data_Package_ID,
       DS.Dataset_ID AS DatasetID,
       DS.Dataset_Num AS Dataset,
       DFP.Dataset_Folder_Path,
       DFP.Archive_Folder_Path,
       InstName.IN_name AS InstrumentName,
       InstName.IN_Group AS InstrumentGroup,
       InstName.IN_class AS InstrumentClass,
       InstClass.raw_data_type AS RawDataType,
       DS.Acq_Time_Start AS Acq_Time_Start,
       DS.DS_Created AS DS_Created,
       Org.Name AS Organism,
       Org.NEWT_ID AS Experiment_NEWT_ID,
       Org.NEWT_Name AS Experiment_NEWT_Name,
       E.Experiment_Num AS Experiment,
       E.EX_reason AS Experiment_Reason,
       E.EX_comment AS Experiment_Comment,
       TPD.[Package Comment] AS PackageComment
FROM T_Data_Package_Datasets TPD
     INNER JOIN S_Dataset DS
       ON TPD.Dataset_ID = DS.Dataset_ID
     INNER JOIN S_V_Dataset_Folder_Paths DFP
       ON DFP.Dataset_ID = DS.Dataset_ID
     INNER JOIN S_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN S_Instrument_Class InstClass
       ON InstName.IN_class = InstClass.IN_class
     INNER JOIN S_Storage_Path SP
       ON DS.DS_storage_path_ID = SP.SP_path_ID
     INNER JOIN S_Experiment_List E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN S_Campaign_List Campaign
       ON E.EX_campaign_ID = Campaign.Campaign_ID
     INNER JOIN S_V_Organism Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN S_V_Dataset_Archive_Path DSArch
       ON DS.Dataset_ID = DSArch.Dataset_ID


GO
