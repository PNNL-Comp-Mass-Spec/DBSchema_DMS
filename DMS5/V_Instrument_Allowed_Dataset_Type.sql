/****** Object:  View [dbo].[V_Instrument_Allowed_Dataset_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Allowed_Dataset_Type]
AS
SELECT GT.Dataset_Type As [Dataset Type],
       CachedUsage.Dataset_Usage_Count As [Dataset Count],
       CachedUsage.Dataset_Usage_Last_Year As [Dataset Count Last Year],
       DTN.DST_Description As [Type Description],
       GT.Comment As [Usage For This Instrument],
       InstName.IN_name As Instrument
FROM t_instrument_group_allowed_ds_type GT
     INNER JOIN T_DatasetTypeName  DTN
       ON GT.Dataset_Type = DTN.DST_name
     INNER JOIN t_instrument_name InstName
       ON GT.IN_Group = InstName.IN_Group
     LEFT OUTER JOIN T_Cached_Instrument_Dataset_Type_Usage CachedUsage
       ON InstName.Instrument_ID = CachedUsage.instrument_id AND
          DTN.DST_name = CachedUsage.dataset_type


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allowed_Dataset_Type] TO [DDL_Viewer] AS [dbo]
GO
