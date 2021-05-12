/****** Object:  View [dbo].[V_EUS_Import_Requested_Allocated_Hours] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Import_Requested_Allocated_Hours]
as
SELECT INSTRUMENT_ID, 
       EUS_DISPLAY_NAME, 
       PROPOSAL_ID, 
       REQUESTED_HOURS, 
       ALLOCATED_HOURS, 
       FY
FROM V_NEXUS_Import_Requested_Allocated_Hours

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Import_Requested_Allocated_Hours] TO [DDL_Viewer] AS [dbo]
GO
