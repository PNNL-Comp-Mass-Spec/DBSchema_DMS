/****** Object:  View [dbo].[V_Unified_Search_For_Organism_ID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Unified_Search_For_Organism_ID
AS
SELECT     Name, Organism_ID, Value_type
FROM         dbo.V_Search_OrganismID_By_ShortName
UNION ALL
SELECT     Name, Organism_ID, Value_type
FROM         dbo.V_Search_OrganismID_By_FullName

GO
