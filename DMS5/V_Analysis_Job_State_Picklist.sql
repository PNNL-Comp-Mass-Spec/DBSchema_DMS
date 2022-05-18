/****** Object:  View [dbo].[V_Analysis_Job_State_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Analysis_Job_State_Picklist
AS
SELECT AJS_stateID As ID, AJS_name As Name, Comment
FROM dbo.T_Analysis_State_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_State_Picklist] TO [DDL_Viewer] AS [dbo]
GO
