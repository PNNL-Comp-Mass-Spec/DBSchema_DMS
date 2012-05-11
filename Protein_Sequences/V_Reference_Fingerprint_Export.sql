/****** Object:  View [dbo].[V_Reference_Fingerprint_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Reference_Fingerprint_Export
AS
SELECT     TOP 100 PERCENT Reference_Fingerprint AS Fingerprint, Reference_ID
FROM         dbo.T_Protein_Names
ORDER BY Reference_ID


GO
