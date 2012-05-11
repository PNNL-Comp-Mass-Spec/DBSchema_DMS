/****** Object:  View [dbo].[V_EUS_Import_Proposals] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_EUS_Import_Proposals
AS
(
SELECT PROPOSAL_ID,
       TITLE,
       CALL_TYPE,
       ACTUAL_END_DATE,
       ACTUAL_START_DATE
FROM openquery ( EUS, 'SELECT * FROM VW_PROPOSALS' )
)
GO
