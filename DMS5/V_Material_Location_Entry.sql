/****** Object:  View [dbo].[V_Material_Location_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Material_Location_Entry]
AS
SELECT ML.id,
       ML.Tag AS location,
       ML.comment,
       ML.status
FROM dbo.T_Material_Locations ML


GO
