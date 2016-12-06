/****** Object:  View [dbo].[V_DMS_Data_Package_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
** This view is used by function LoadDataPackageJobInfo in the DMS Analysis Manager
**
*/
CREATE VIEW [dbo].[V_DMS_Data_Package_Datasets]
AS
SELECT Data_Package_ID,
       DatasetID,
       Dataset,
       Dataset_Folder_Path,
       Archive_Folder_Path,
       InstrumentName AS Instrument,
       InstrumentGroup,
       InstrumentClass,
       RawDataType,
       Acq_Time_Start,
       DS_Created,
       Organism,
       Experiment_NEWT_ID,
       Experiment_NEWT_Name,
       Experiment,
       Experiment_Reason,
       Experiment_Comment,
       ISNULL(PackageComment, '') AS PackageComment
FROM S_Data_Package_Aggregation_Datasets


GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_Data_Package_Datasets] TO [DDL_Viewer] AS [dbo]
GO
