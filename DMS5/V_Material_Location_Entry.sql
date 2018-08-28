/****** Object:  View [dbo].[V_Material_Location_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Material_Location_Entry]
AS
SELECT ML.ID AS ID,
       ML.Tag AS [Location],
       ML.[Comment],
       ML.[Status]       
FROM dbo.T_Material_Locations ML


GO
