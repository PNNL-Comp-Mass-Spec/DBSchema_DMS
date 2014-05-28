/****** Object:  View [dbo].[V_Instrument_Name_RNA_PickList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Instrument_Name_RNA_PickList] as
SELECT InstName.IN_name As Instrument,
       I.Usage as [Usage],
       dbo.GetInstrumentGroupDatasetTypeList(I.IN_Group) AS Allowed_Dataset_Types
FROM T_Instrument_Name InstName
     INNER JOIN T_Instrument_Group I
       ON InstName.IN_Group = I.IN_Group
     LEFT OUTER JOIN T_DatasetTypeName DT
       ON I.Default_Dataset_Type = DT.DST_Type_ID
WHERE (InstName.IN_operations_role = 'Transcriptomics') AND
      (InstName.IN_status <> 'Inactive')

GO
