/****** Object:  View [dbo].[V_EUS_Proposals_Helper_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_EUS_Proposals_Helper_List_Report
AS
SELECT     dbo.T_EUS_Proposals.PROPOSAL_ID AS [Proposal ID], dbo.T_EUS_Proposals.TITLE, ISNULL(CONVERT(varchar(16), 
                      dbo.T_Requested_Run_History.ID), '(none yet)') AS Request, ISNULL(dbo.T_Dataset.Dataset_Num, '(none yet)') AS Dataset
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Requested_Run_History ON dbo.T_Dataset.Dataset_ID = dbo.T_Requested_Run_History.DatasetID RIGHT OUTER JOIN
                      dbo.T_EUS_Proposals ON dbo.T_Requested_Run_History.RDS_EUS_Proposal_ID = dbo.T_EUS_Proposals.PROPOSAL_ID
WHERE     (dbo.T_EUS_Proposals.State_ID = 2)

GO
