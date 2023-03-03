/****** Object:  View [dbo].[V_Instrument_Allowed_Dataset_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Allowed_Dataset_Type]
AS
SELECT GT.dataset_type,
       CachedUsage.Dataset_Usage_Count As dataset_usage_count,
       CachedUsage.Dataset_Usage_Last_Year As dataset_usage_last_year,
       DTN.DST_Description As type_description,
       GT.Comment As usage_for_this_instrument,
       InstName.IN_name As instrument
FROM t_instrument_group_allowed_ds_type GT
     INNER JOIN T_Dataset_Type_Name  DTN
       ON GT.Dataset_Type = DTN.DST_name
     INNER JOIN t_instrument_name InstName
       ON GT.IN_Group = InstName.IN_Group
     LEFT OUTER JOIN T_Cached_Instrument_Dataset_Type_Usage CachedUsage
       ON InstName.Instrument_ID = CachedUsage.instrument_id AND
          DTN.DST_name = CachedUsage.dataset_type

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allowed_Dataset_Type] TO [DDL_Viewer] AS [dbo]
GO
