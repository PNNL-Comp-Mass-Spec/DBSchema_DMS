/****** Object:  View [dbo].[V_EUS_Usage_Type_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Usage_Type_List_Report]
AS
SELECT ID,
       Name,
       Description,
       Enabled,
       Enabled_Campaign,
       Enabled_Prep_Request
FROM T_EUS_UsageType


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Usage_Type_List_Report] TO [DDL_Viewer] AS [dbo]
GO
