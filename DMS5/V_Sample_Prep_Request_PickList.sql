/****** Object:  View [dbo].[V_Sample_Prep_Request_PickList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Sample_Prep_Request_PickList
AS
SELECT SPR.ID,
       SPR.Request_Name AS Request_Name,
	   SPR.Request_Type As [Type],
       SPR.Created,
       SPR.Priority,
       SN.State_Name AS [State],
       CONVERT(varchar(42), SPR.Reason) AS Reason,
       SPR.Number_of_Samples AS NumSamples,
       SPR.Prep_Method AS PrepMethod,
       SPR.Assigned_Personnel AS AssignedPersonnel,
       SPR.Organism,
       SPR.Campaign
FROM    T_Sample_Prep_Request AS SPR
        INNER JOIN T_Sample_Prep_Request_State_Name AS SN ON SPR.State = SN.State_ID
WHERE (SPR.State > 0) 
GROUP BY SPR.ID, SPR.Request_Name, SPR.Created, SPR.Estimated_Completion, SPR.Priority, 
         SPR.State, SN.State_Name, SPR.Request_Type, SPR.Reason, SPR.Number_of_Samples, SPR.Estimated_MS_runs,
         SPR.Prep_Method, SPR.Requested_Personnel, SPR.Assigned_Personnel,
         SPR.Requester_PRN, SPR.Organism, SPR.Biohazard_Level, SPR.Campaign


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_PickList] TO [DDL_Viewer] AS [dbo]
GO
