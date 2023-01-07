/****** Object:  View [dbo].[V_Instrument_Group_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Group_List_Report]
AS
SELECT I.IN_Group AS instrument_group,
       I.usage,
       I.comment,
       I.active,
       I.sample_prep_visible,
       I.requested_run_visible,
       I.allocation_tag,
       ISNULL(DT.dst_name, '') AS default_dataset_type,
       dbo.GetInstrumentGroupMembershipList(I.in_group, 0, 0) AS instruments,
       dbo.GetInstrumentGroupDatasetTypeList(I.in_group, ', ') AS allowed_dataset_types
FROM dbo.T_Instrument_Group I
     LEFT OUTER JOIN dbo.T_DatasetTypeName DT
       ON I.Default_Dataset_Type = DT.DST_Type_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Group_List_Report] TO [DDL_Viewer] AS [dbo]
GO
