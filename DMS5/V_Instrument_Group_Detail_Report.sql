/****** Object:  View [dbo].[V_Instrument_Group_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Group_Detail_Report] as 
SELECT I.IN_Group AS Instrument_Group,
       I.Usage,
       I.Comment,
       I.Active,
       I.Sample_Prep_Visible,
       I.Requested_Run_Visible,
       I.Allocation_Tag,
       ISNULL(DT.DST_name, '') AS [Default Dataset Type],
       '!Headers!Instrument Name:Instrument ID|' + dbo.GetInstrumentGroupMembershipList(I.IN_Group, 2, 0) AS Instruments,
       dbo.GetInstrumentGroupDatasetTypeList(I.IN_Group, ', ') AS Allowed_Dataset_Types
FROM T_Instrument_Group I
     LEFT OUTER JOIN dbo.T_DatasetTypeName DT
       ON I.Default_Dataset_Type = DT.DST_Type_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Group_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
