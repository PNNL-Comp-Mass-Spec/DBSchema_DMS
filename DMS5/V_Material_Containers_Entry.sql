/****** Object:  View [dbo].[V_Material_Containers_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Material_Containers_Entry]
AS
SELECT MC.Tag AS container,
       MC.type,
       ML.Tag AS location,
       MC.status,
       MC.comment,
       C.Campaign_Num AS campaign,
       MC.researcher
FROM dbo.T_Material_Containers MC
     INNER JOIN dbo.T_Material_Locations ML
       ON MC.Location_ID = ML.ID
     LEFT OUTER JOIN T_Campaign C
       ON MC.Campaign_ID = C.Campaign_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Containers_Entry] TO [DDL_Viewer] AS [dbo]
GO
