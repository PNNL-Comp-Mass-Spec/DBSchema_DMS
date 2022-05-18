/****** Object:  View [dbo].[V_Enzyme_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Enzyme_Picklist
As
SELECT Enzyme_ID As ID, Enzyme_Name As Name
FROM T_Enzymes 
WHERE Enzyme_ID > 0

GO
GRANT VIEW DEFINITION ON [dbo].[V_Enzyme_Picklist] TO [DDL_Viewer] AS [dbo]
GO
