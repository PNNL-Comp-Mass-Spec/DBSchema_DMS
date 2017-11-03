/****** Object:  View [dbo].[V_Freezer_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Freezer_List_Report]
AS
SELECT F.Freezer_ID,
       F.Freezer,
       F.Freezer_Tag,
       F.[Comment],
       COUNT(MC.ID) AS Containers
FROM T_Material_Containers MC
     INNER JOIN T_Material_Locations ML
       ON MC.Location_ID = ML.ID
     RIGHT OUTER JOIN T_Material_Freezers F
       ON ML.Freezer_Tag = F.Freezer_Tag AND
          ML.Status <> 'Inactive' AND
          MC.Status <> 'Inactive'
GROUP BY F.Freezer_ID, F.Freezer, F.Freezer_Tag, F.[Comment], ML.Status


GO
