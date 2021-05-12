/****** Object:  View [dbo].[V_NEXUS_Import_Requested_Allocated_Hours] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_NEXUS_Import_Requested_Allocated_Hours]
As
(
SELECT instrument_id, 
       eus_display_name, 
       proposal_id, 
       requested_hours, 
       allocated_hours, 
       fy
FROM openquery ( NEXUS, 'SELECT * FROM proteomics_views.vw_requested_allocated_hours' )
)

GO
