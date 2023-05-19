/****** Object:  View [dbo].[V_EUS_Usage_Type_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_EUS_Usage_Type_List_Report]
AS
SELECT id,
       name AS eus_usage_type,
       description,
       enabled,
       enabled_campaign,
       enabled_prep_request
FROM T_EUS_UsageType

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Usage_Type_List_Report] TO [DDL_Viewer] AS [dbo]
GO
