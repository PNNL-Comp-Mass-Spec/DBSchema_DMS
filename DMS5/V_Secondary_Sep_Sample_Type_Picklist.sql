/****** Object:  View [dbo].[V_Secondary_Sep_Sample_Type_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Secondary_Sep_Sample_Type_Picklist
As
SELECT SampleType_ID As ID, Name
FROM T_Secondary_Sep_SampleType    


GO
GRANT VIEW DEFINITION ON [dbo].[V_Secondary_Sep_Sample_Type_Picklist] TO [DDL_Viewer] AS [dbo]
GO
