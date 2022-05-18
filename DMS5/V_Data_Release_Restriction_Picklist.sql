/****** Object:  View [dbo].[V_Data_Release_Restriction_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Data_Release_Restriction_Picklist
As
SELECT ID, Name
FROM T_Data_Release_Restrictions   


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Release_Restriction_Picklist] TO [DDL_Viewer] AS [dbo]
GO
