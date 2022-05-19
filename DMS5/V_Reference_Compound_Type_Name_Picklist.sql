/****** Object:  View [dbo].[V_Reference_Compound_Type_Name_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Reference_Compound_Type_Name_Picklist
As
SELECT Compound_Type_ID As ID, Compound_Type_Name As Name
FROM T_Reference_Compound_Type_Name 


GO
GRANT VIEW DEFINITION ON [dbo].[V_Reference_Compound_Type_Name_Picklist] TO [DDL_Viewer] AS [dbo]
GO
