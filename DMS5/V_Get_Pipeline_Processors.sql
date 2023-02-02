/****** Object:  View [dbo].[V_Get_Pipeline_Processors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Get_Pipeline_Processors]
AS
SELECT P.id,
       P.processor_name,
       P.state,
       COUNT(ISNULL(PGM.Group_ID, 0)) AS groups,
       SUM(1) AS gp_groups,
       /*
	    * Deprecated in February 2015; now always reports 1 for General_Processing
        * SUM(CASE WHEN PGA.Available_For_General_Processing = 'Y' THEN 1 ELSE 0 END) AS GP_Groups,
        */
       P.machine
FROM dbo.T_Analysis_Job_Processors P
     LEFT OUTER JOIN dbo.T_Analysis_Job_Processor_Group_Membership PGM
       ON P.ID = PGM.Processor_ID
     -- INNER JOIN dbo.T_Analysis_Job_Processor_Group PGA
     --  ON PGM.Group_ID = PGA.ID
WHERE PGM.Membership_Enabled = 'Y'
GROUP BY P.Processor_Name, P.State, P.ID, P.Machine


GO
GRANT VIEW DEFINITION ON [dbo].[V_Get_Pipeline_Processors] TO [DDL_Viewer] AS [dbo]
GO
