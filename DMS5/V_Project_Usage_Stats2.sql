/****** Object:  View [dbo].[V_Project_Usage_Stats2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Project_Usage_Stats2]
AS
-- Show project stats for this week and the previous week, filtering out Maintenance and Cap_Dev that are not associated with a user proposal
SELECT 	Entry_ID,
		Start_Date,
		End_Date,
		[Year],
		[Week],
		Proposal_ID,
		Work_Package,
		Proposal_Active,
		Project_Type,
		Samples,
		Datasets,
		Jobs,
		Usage_Type,
		Proposal_User,
		Proposal_Title,
		Instrument_First,
		Instrument_Last,
		Job_Tool_First,
		Job_Tool_Last,
		Proposal_Start_Date,
		Proposal_End_Date,
		Proposal_Type,
		Sort_Key
FROM V_Project_Usage_Stats
WHERE [Year] = DATEPART(year, GETDATE()) AND [Week] >= DATEPART(week, GETDATE()) - 1 AND
      (NOT (Usage_Type IN ('CAP_DEV', 'MAINTENANCE', 'RESOURCE_OWNER') AND Project_Type = 'Unknown'))

GO
GRANT VIEW DEFINITION ON [dbo].[V_Project_Usage_Stats2] TO [DDL_Viewer] AS [dbo]
GO
