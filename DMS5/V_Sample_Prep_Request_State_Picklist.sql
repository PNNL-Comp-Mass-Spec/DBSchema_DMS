/****** Object:  View [dbo].[V_Sample_Prep_Request_State_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_State_Picklist]
AS
SELECT State_Name AS val,
       State_Name AS ex,
       State_ID AS state_id
FROM T_Sample_Prep_Request_State_Name
WHERE (Active = 1)
-- Deprecated:
-- UNION
-- SELECT 'Closed (containers and material)' AS val, 'Closed (containers and material)' AS ex, 99 AS State_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_State_Picklist] TO [DDL_Viewer] AS [dbo]
GO
