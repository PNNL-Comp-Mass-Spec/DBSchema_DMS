/****** Object:  View [dbo].[V_Material_Containers_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Material_Containers_Entry
AS
SELECT MC.Tag AS container,
       MC.type,
       ML.Tag AS location,
       MC.status,
       MC.comment,
       MC.barcode,
       MC.researcher
FROM dbo.T_Material_Containers MC
     INNER JOIN dbo.T_Material_Locations ML
       ON MC.Location_ID = ML.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Containers_Entry] TO [DDL_Viewer] AS [dbo]
GO
