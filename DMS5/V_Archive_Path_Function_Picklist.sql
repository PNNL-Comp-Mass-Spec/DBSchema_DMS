/****** Object:  View [dbo].[V_Archive_Path_Function_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Archive_Path_Function_Picklist
As
SELECT APF_Function as Name
FROM T_Archive_Path_Function


GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Path_Function_Picklist] TO [DDL_Viewer] AS [dbo]
GO
