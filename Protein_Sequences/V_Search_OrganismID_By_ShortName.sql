/****** Object:  View [dbo].[V_Search_OrganismID_By_ShortName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Search_OrganismID_By_ShortName
AS
SELECT     ID AS Organism_ID, Short_Name AS Name, 'organismIDByShortName' AS Value_type
FROM         dbo.V_Organism_Picker

GO
