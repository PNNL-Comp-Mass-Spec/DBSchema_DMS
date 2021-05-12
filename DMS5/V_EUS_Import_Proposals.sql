/****** Object:  View [dbo].[V_EUS_Import_Proposals] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Import_Proposals]
AS
(
SELECT project_id As PROPOSAL_ID,
       TITLE,
       proposal_type_display As PROPOSAL_TYPE,
       ACTUAL_END_DATE,
       ACTUAL_START_DATE
FROM V_NEXUS_Import_Proposals
)

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Import_Proposals] TO [DDL_Viewer] AS [dbo]
GO
