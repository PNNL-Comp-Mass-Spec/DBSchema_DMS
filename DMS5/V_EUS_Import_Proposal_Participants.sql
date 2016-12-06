/****** Object:  View [dbo].[V_EUS_Import_Proposal_Participants] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Import_Proposal_Participants]
AS
(
SELECT PROPOSAL_ID,
       PERSON_ID,
       HANFORD_ID,
       LAST_NAME,
       FIRST_NAME,
       LAST_NAME + ', ' + FIRST_NAME AS NAME_FM
FROM openquery (EUS, 'SELECT * FROM VW_PROPOSAL_PARTICIPANTS')
)


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Import_Proposal_Participants] TO [DDL_Viewer] AS [dbo]
GO
