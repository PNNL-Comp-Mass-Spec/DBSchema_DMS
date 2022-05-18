/****** Object:  View [dbo].[V_Analysis_Job_Request_State_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Analysis_Job_Request_State_Picklist
AS
SELECT ID, StateName As Name
FROM dbo.T_Analysis_Job_Request_State
WHERE StateName <> 'na'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Request_State_Picklist] TO [DDL_Viewer] AS [dbo]
GO
