/****** Object:  View [dbo].[V_MAC_Job_Type_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_MAC_Job_Type_Picklist
As
SELECT ID, Script, Description
FROM T_Scripts 
WHERE Script Like 'MAC[_]%' And Enabled = 'Y' AND NOT Parameters IS NULL


GO
GRANT VIEW DEFINITION ON [dbo].[V_MAC_Job_Type_Picklist] TO [DDL_Viewer] AS [dbo]
GO
