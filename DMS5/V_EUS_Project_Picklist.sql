/****** Object:  View [dbo].[V_EUS_Project_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_EUS_Project_Picklist
AS
SELECT ID, Name
FROM dbo.T_EUS_Proposal_State_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Project_Picklist] TO [DDL_Viewer] AS [dbo]
GO
