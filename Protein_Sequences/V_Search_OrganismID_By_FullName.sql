/****** Object:  View [dbo].[V_Search_OrganismID_By_FullName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Search_OrganismID_By_FullName
AS
SELECT     ID AS Organism_ID, Organism_Name AS Name, 'organismIDByFullName' AS Value_type
FROM         dbo.V_Organism_Picker

GO
