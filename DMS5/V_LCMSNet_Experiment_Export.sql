/****** Object:  View [dbo].[V_LCMSNet_Experiment_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LCMSNet_Experiment_Export]
AS
SELECT E.Exp_ID AS ID,
       E.Experiment_Num AS Experiment,
       U.Name_with_PRN AS Researcher,
       Org.OG_name AS Organism,
       E.EX_reason AS Reason,
       E.EX_comment AS [Comment],
       E.EX_created AS Created,
       E.EX_sample_prep_request_ID AS Request,
	   E.Last_Used
FROM T_Experiments E
     INNER JOIN dbo.T_Users U
       ON E.EX_researcher_PRN = U.U_PRN
     INNER JOIN dbo.T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID


GO
