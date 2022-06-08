/****** Object:  View [dbo].[V_Data_Package_EUS_Proposals_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_EUS_Proposals_List_Report]
AS
SELECT DPP.Data_Package_ID AS ID,
       DPP.Proposal_ID,
       PL.Title,
       PL.Users,
       PL.State,
       DPP.Item_Added
FROM T_Data_Package_EUS_Proposals DPP
     INNER JOIN S_V_EUS_Proposals_List_Report PL
       ON PL.ID = DPP.Proposal_ID




GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_EUS_Proposals_List_Report] TO [DDL_Viewer] AS [dbo]
GO
