/****** Object:  View [dbo].[V_Protein_Database_Export_Web] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Protein_Database_Export_Web
AS
SELECT     TOP (100) PERCENT Protein_ID, Reference_ID, Name, LEFT(Description, 500) AS Description, Sequence, Sorting_Index, Protein_Collection_ID, 
                      Length
FROM         dbo.V_Protein_Storage_Entry_Import
ORDER BY Sorting_Index

GO
