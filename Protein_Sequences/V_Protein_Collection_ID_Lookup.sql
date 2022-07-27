/****** Object:  View [dbo].[V_Protein_Collection_ID_Lookup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Collection_ID_Lookup]
AS
SELECT Protein_Collection_ID AS Collection_ID,
       Collection_Name AS Collection_Name,
       Description
FROM dbo.T_Protein_Collections

GO
