/****** Object:  View [dbo].[V_Analysis_Job_Additional_Parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Analysis_Job_Additional_Parameters]
AS
SELECT     dbo.T_Analysis_Job.AJ_jobID AS Job, dbo.T_Instrument_Class.IN_class AS InstrumentClass, dbo.T_Instrument_Class.raw_data_type AS RawDataType,
                       dbo.T_Analysis_Tool.AJT_searchEngineInputFileFormats AS SearchEngineInputFileFormats, dbo.T_Organisms.OG_name AS OrganismName, 
                      dbo.T_Analysis_Tool.AJT_orgDbReqd AS OrgDbReqd, dbo.T_Analysis_Job.AJ_proteinCollectionList AS ProteinCollectionList, 
                      dbo.T_Analysis_Job.AJ_proteinOptionsList AS ProteinOptionsList
FROM         dbo.T_Analysis_Job INNER JOIN
                      dbo.T_Dataset ON dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_Instrument_Class ON dbo.T_Instrument_Name.IN_class = dbo.T_Instrument_Class.IN_class INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Analysis_Job.AJ_organismID = dbo.T_Organisms.Organism_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Additional_Parameters] TO [PNL\D3M578] AS [dbo]
GO
