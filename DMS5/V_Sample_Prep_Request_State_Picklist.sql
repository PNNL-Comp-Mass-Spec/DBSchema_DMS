/****** Object:  View [dbo].[V_Sample_Prep_Request_State_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view V_Sample_Prep_Request_State_Picklist as 
SELECT State_Name AS val, State_Name AS ex,  State_ID FROM T_Sample_Prep_Request_State_Name WHERE (State_ID > 0) 
UNION
SELECT 'Closed (containers and material)' AS val, 'Closed (containers and material)' AS ex, 6 AS State_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_State_Picklist] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_State_Picklist] TO [PNL\D3M580] AS [dbo]
GO
