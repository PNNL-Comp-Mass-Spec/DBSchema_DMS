/****** Object:  View [dbo].[V_NEXUS_Import_Proposal_Participants] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_NEXUS_Import_Proposal_Participants]
As
(
SELECT project_id,
       user_id,
       hanford_id,
       last_name,
       first_name,
       name_fm
FROM openquery ( NEXUS, 'SELECT * FROM proteomics_views.vw_proposal_participants' )
)

GO
