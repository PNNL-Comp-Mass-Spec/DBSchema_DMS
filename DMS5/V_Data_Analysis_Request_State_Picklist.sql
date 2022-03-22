/****** Object:  View [dbo].[V_Data_Analysis_Request_State_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Analysis_Request_State_Picklist]
AS 
SELECT State_Name AS val,
       State_Name AS ex,
       State_ID
FROM T_Data_Analysis_Request_State_Name
WHERE (Active = 1)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Analysis_Request_State_Picklist] TO [DDL_Viewer] AS [dbo]
GO
