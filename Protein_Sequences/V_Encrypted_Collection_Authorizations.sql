/****** Object:  View [dbo].[V_Encrypted_Collection_Authorizations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Encrypted_Collection_Authorizations
AS
SELECT     dbo.T_Encrypted_Collection_Authorizations.Login_Name, dbo.T_Encrypted_Collection_Authorizations.Protein_Collection_ID, 
                      CASE WHEN T_Encrypted_Collection_Authorizations.Protein_Collection_ID = 0 THEN 'Administrator' ELSE [filename] END AS Protein_Collection_Name
FROM         dbo.T_Encrypted_Collection_Authorizations LEFT OUTER JOIN
                      dbo.T_Protein_Collections ON dbo.T_Encrypted_Collection_Authorizations.Protein_Collection_ID = dbo.T_Protein_Collections.Protein_Collection_ID

GO
