/****** Object:  View [dbo].[V_Instrument_Group_PickList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Instrument_Group_PickList] as
SELECT I.IN_Group AS Instrument_Group,
       I.Usage,
       dbo.GetInstrumentGroupMembershipList(I.IN_Group) AS Instruments,
       I.Comment,
       dbo.GetInstrumentGroupDatasetTypeList(I.IN_Group) AS Allowed_Dataset_Types
FROM dbo.T_Instrument_Group I
     LEFT OUTER JOIN dbo.T_DatasetTypeName DT
       ON I.Default_Dataset_Type = DT.DST_Type_ID
WHERE I.Active > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Group_PickList] TO [PNL\D3M578] AS [dbo]
GO
