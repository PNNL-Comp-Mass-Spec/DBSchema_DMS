/****** Object:  View [dbo].[V_Instrument_Allowed_Dataset_Type_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Allowed_Dataset_Type_List_Report]
AS
SELECT 'Edit' AS sel,
       IGADT.IN_Group AS instrument_group,
       IGADT.dataset_type,
       DTN.DST_Description AS type_description,
       IGADT.Comment AS usage_for_this_group
FROM T_Instrument_Group_Allowed_DS_Type IGADT
     INNER JOIN T_DatasetTypeName DTN
       ON IGADT.Dataset_Type = DTN.DST_name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allowed_Dataset_Type_List_Report] TO [DDL_Viewer] AS [dbo]
GO
