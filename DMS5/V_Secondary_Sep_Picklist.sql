/****** Object:  View [dbo].[V_Secondary_Sep_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Secondary_Sep_Picklist
As
SELECT SS_ID As ID, SS_Name As Name, SS_comment As Comment, Sep_Group As Separation_Group
FROM T_Secondary_Sep  
WHERE SS_active > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Secondary_Sep_Picklist] TO [DDL_Viewer] AS [dbo]
GO
