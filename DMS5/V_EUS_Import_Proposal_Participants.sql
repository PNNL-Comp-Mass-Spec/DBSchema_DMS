/****** Object:  View [dbo].[V_EUS_Import_Proposal_Participants] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Import_Proposal_Participants]
AS
(
SELECT project_id As PROPOSAL_ID,
       user_id as PERSON_ID,
       HANFORD_ID,
       LAST_NAME,
       FIRST_NAME,
       NAME_FM,
       LAST_NAME + ', ' + FIRST_NAME AS NAME_FM_Computed
FROM V_NEXUS_Import_Proposal_Participants
)

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Import_Proposal_Participants] TO [DDL_Viewer] AS [dbo]
GO
