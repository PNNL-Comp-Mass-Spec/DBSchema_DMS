/****** Object:  View [dbo].[V_Instrument_Group_Allowed_Dataset_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Group_Allowed_Dataset_Type]
AS
SELECT GT.Dataset_Type AS dataset_type,
       GT.Dataset_Usage_Count AS dataset_count,
       GT.Dataset_Usage_Last_Year AS dataset_count_last_year,
       DTN.DST_Description AS type_description,
       GT.Comment AS usage_for_this_group,
       GT.IN_Group AS instrument_group
FROM T_Instrument_Group_Allowed_DS_Type GT
     INNER JOIN T_Dataset_Type_Name DTN
       ON GT.Dataset_Type = DTN.DST_name

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Group_Allowed_Dataset_Type] TO [DDL_Viewer] AS [dbo]
GO
