/****** Object:  View [dbo].[V_Instrument_Group_Allowed_Dataset_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Group_Allowed_Dataset_Type]
AS
SELECT GT.Dataset_Type AS [Dataset Type],
       GT.Dataset_Usage_Count AS [Dataset Count],
       GT.Dataset_Usage_Last_Year AS [Dataset Count Last Year],
       DTN.DST_Description AS [Type Description],
       GT.[Comment] AS [Usage For This Group],
       GT.IN_Group AS [Instrument Group]
FROM T_Instrument_Group_Allowed_DS_Type GT
     INNER JOIN T_DatasetTypeName DTN
       ON GT.Dataset_Type = DTN.DST_name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Group_Allowed_Dataset_Type] TO [DDL_Viewer] AS [dbo]
GO
