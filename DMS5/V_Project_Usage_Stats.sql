/****** Object:  View [dbo].[V_Project_Usage_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Project_Usage_Stats]
AS
SELECT Stats.entry_id,
       Stats.StartDate AS start_date,
       Stats.EndDate AS end_date,
       Stats.TheYear As year,
       Stats.WeekOfYear As week,
       Stats.proposal_id,
       Stats.RDS_WorkPackage AS work_package,
       Stats.proposal_active,
       ProjectTypes.Project_Type_Name AS project_type,
	   Stats.samples,
       Stats.datasets,
       Stats.jobs,
       EUSUsage.Name AS usage_type,
       Stats.proposal_user,
       Proposals.Title AS proposal_title,
       Stats.instrument_first,
       Stats.instrument_last,
       Stats.JobTool_First AS job_tool_first,
       Stats.JobTool_Last  AS job_tool_last,
       Cast(Proposals.Proposal_Start_Date AS date) AS proposal_start_date,
       Cast(Proposals.Proposal_End_Date AS date) AS proposal_end_date,
       Stats.proposal_type,
       Stats.SortKey AS sort_key
FROM T_Project_Usage_Stats Stats
     INNER JOIN T_Project_Usage_Types ProjectTypes
       ON Stats.Project_Type_ID = ProjectTypes.Project_Type_ID
     INNER JOIN T_EUS_UsageType EUSUsage
       ON Stats.EUS_UsageType = EUSUsage.ID
     LEFT OUTER JOIN T_EUS_Proposals Proposals
       ON Stats.Proposal_ID = Proposals.Proposal_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Project_Usage_Stats] TO [DDL_Viewer] AS [dbo]
GO
