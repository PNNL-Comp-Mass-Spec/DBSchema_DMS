/****** Object:  View [dbo].[V_EUS_Proposals_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_EUS_Proposals_Detail_Report]
AS
SELECT EUP.Proposal_ID AS id,
       S.Name AS state,
       EUP.title,
       EUP.Proposal_Type AS proposal_type,
       EPT.Proposal_Type_Name AS proposal_type_name,
       EPT.Abbreviation AS abbreviation,
       EUP.Proposal_Start_Date AS proposal_start_date,
       EUP.Proposal_End_Date AS proposal_end_date,
       EUP.Import_Date AS import_date,
       EUP.last_affected,
       EUP.Proposal_ID_AutoSupersede As superseded_by,
       dbo.get_proposal_eus_users_list(EUP.proposal_id, 'V', 1000) AS eus_users
FROM dbo.T_EUS_Proposals EUP
     INNER JOIN T_EUS_Proposal_State_Name S
       ON EUP.State_ID = S.ID
     LEFT OUTER JOIN T_EUS_Proposal_Type EPT
       ON EUP.Proposal_Type = EPT.Proposal_Type

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposals_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
