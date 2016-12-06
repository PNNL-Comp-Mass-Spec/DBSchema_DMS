/****** Object:  View [dbo].[V_Project_Usage_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Project_Usage_Stats]
AS
SELECT Stats.Entry_ID,
       Stats.StartDate,
       Stats.EndDate,
       Stats.TheYear as [Year],
       Stats.WeekOfYear as [Week],
       Stats.Proposal_ID,
       Stats.RDS_WorkPackage as Work_Package,
       Stats.Proposal_Active,
       ProjectTypes.Project_Type_Name as Project_Type,
	   Stats.Samples,
       Stats.Datasets,
       Stats.Jobs,
       EUSUsage.Name AS Usage_Type,
       Stats.Proposal_User,
       Proposals.Title AS Proposal_Title,
       Stats.Instrument_First,
       Stats.Instrument_Last,
       Stats.JobTool_First,
       Stats.JobTool_Last,
       Cast(Proposals.Proposal_Start_Date AS date) AS Proposal_Start_Date,
       Cast(Proposals.Proposal_End_Date AS date) AS Proposal_End_Date,
       Stats.Proposal_Type,
       Stats.SortKey
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
