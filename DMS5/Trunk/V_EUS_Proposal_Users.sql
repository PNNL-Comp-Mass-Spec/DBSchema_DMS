/****** Object:  View [dbo].[V_EUS_Proposal_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create VIEW V_EUS_Proposal_Users
AS
SELECT     T_EUS_Users.PERSON_ID AS [User ID], T_EUS_Users.NAME_FM AS [User Name], T_EUS_Proposal_Users.Proposal_ID AS [#Proposal]
FROM         T_EUS_Proposal_Users INNER JOIN
                      T_EUS_Users ON T_EUS_Proposal_Users.Person_ID = T_EUS_Users.PERSON_ID
WHERE     (T_EUS_Proposal_Users.Of_DMS_Interest = 'Y')

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposal_Users] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposal_Users] TO [PNL\D3M580] AS [dbo]
GO
