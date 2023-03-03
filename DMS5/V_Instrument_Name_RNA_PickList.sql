/****** Object:  View [dbo].[V_Instrument_Name_RNA_PickList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Name_RNA_PickList] as
SELECT InstName.IN_name As Instrument,
       I.Usage as [Usage],
       dbo.get_instrument_group_dataset_type_list(I.IN_Group, ', ') AS Allowed_Dataset_Types
FROM T_Instrument_Name InstName
     INNER JOIN T_Instrument_Group I
       ON InstName.IN_Group = I.IN_Group
     LEFT OUTER JOIN T_Dataset_Type_Name DT
       ON I.Default_Dataset_Type = DT.DST_Type_ID
WHERE (InstName.IN_operations_role = 'Transcriptomics') AND
      (InstName.IN_status <> 'Inactive')

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Name_RNA_PickList] TO [DDL_Viewer] AS [dbo]
GO
