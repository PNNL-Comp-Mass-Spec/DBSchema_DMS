/****** Object:  View [dbo].[V_NEXUS_Import_Proposals] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_NEXUS_Import_Proposals]
AS
(
SELECT project_id, 
       title, 
       proposal_type,
       proposal_type_display,
       actual_start_date, 
       actual_end_date,
       project_uuid,
       Row_Number() Over (Partition By project_id Order By actual_start_date, actual_end_date) As IdRank
FROM openquery ( NEXUS, 'SELECT * FROM proteomics_views.vw_proposals' )
)

GO
