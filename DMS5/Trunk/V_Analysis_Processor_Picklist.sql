/****** Object:  View [dbo].[V_Analysis_Processor_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Processor_Picklist
AS
SELECT     TOP 100 PERCENT Processor_Name AS val, '' AS ex
FROM         dbo.T_Analysis_Job_Processors
WHERE     (State = 'E')
ORDER BY val

GO
