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
       PROPOSAL_TYPE,
       ACTUAL_END_DATE,
       ACTUAL_START_DATE
FROM openquery ( EUS, 'SELECT * FROM VW_PROPOSALS' )
)
GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Import_Proposals] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Import_Proposals] TO [PNL\D3M580] AS [dbo]
GO
