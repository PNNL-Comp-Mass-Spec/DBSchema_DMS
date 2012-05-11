/****** Object:  View [dbo].[V_Unified_Search_For_Collection_ID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Unified_Search_For_Collection_ID
AS
SELECT     Name, Collection_ID, Value_type
FROM         dbo.V_Search_CollectionID_By_CollectionName
UNION ALL
SELECT     Name, Collection_ID, Value_type
FROM         dbo.V_Search_CollectionID_By_OrganismName

GO
