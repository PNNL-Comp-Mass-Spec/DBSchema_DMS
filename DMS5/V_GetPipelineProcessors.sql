/****** Object:  View [dbo].[V_GetPipelineProcessors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_GetPipelineProcessors]
AS
SELECT     dbo.T_Analysis_Job_Processors.ID, dbo.T_Analysis_Job_Processors.Processor_Name, dbo.T_Analysis_Job_Processors.State, 
                      COUNT(ISNULL(dbo.T_Analysis_Job_Processor_Group_Membership.Group_ID, 0)) AS Groups, 
                      SUM(1) AS GP_Groups, 
                      /*
	                   * Deprecated in February 2015; now always reports 1 for General_Processing
                       * SUM(CASE WHEN T_Analysis_Job_Processor_Group.Available_For_General_Processing = 'Y' THEN 1 ELSE 0 END) AS GP_Groups, 
                       */
                      dbo.T_Analysis_Job_Processors.Machine
FROM         dbo.T_Analysis_Job_Processors LEFT OUTER JOIN
                      dbo.T_Analysis_Job_Processor_Group_Membership ON 
                      dbo.T_Analysis_Job_Processors.ID = dbo.T_Analysis_Job_Processor_Group_Membership.Processor_ID INNER JOIN
                      dbo.T_Analysis_Job_Processor_Group ON 
                      dbo.T_Analysis_Job_Processor_Group_Membership.Group_ID = dbo.T_Analysis_Job_Processor_Group.ID
WHERE     (dbo.T_Analysis_Job_Processor_Group_Membership.Membership_Enabled = 'Y')
GROUP BY dbo.T_Analysis_Job_Processors.Processor_Name, dbo.T_Analysis_Job_Processors.State, dbo.T_Analysis_Job_Processors.ID, 
                      dbo.T_Analysis_Job_Processors.Machine


GO
GRANT VIEW DEFINITION ON [dbo].[V_GetPipelineProcessors] TO [PNL\D3M578] AS [dbo]
GO
