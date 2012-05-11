/****** Object:  View [dbo].[V_Protein_Fingerprint_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Protein_Fingerprint_Export
AS
SELECT     TOP 100 PERCENT SHA1_Hash AS Fingerprint, Protein_ID, Length
FROM         dbo.T_Proteins
ORDER BY Protein_ID


GO
GRANT SELECT ON [dbo].[V_Protein_Fingerprint_Export] TO [pnl\d3l243] AS [dbo]
GO
