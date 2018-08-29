/****** Object:  View [dbo].[V_Material_Log_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Material_Log_List_Report]
AS
SELECT ML.ID,
       ML.[Date],
       ML.Type_Name_Cached AS [Type],
       ML.Item,
       ML.Initial_State AS Initial,
       ML.Final_State AS Final,
       U.Name_with_PRN AS [User],
       ML.[Comment],
       TMC.[Comment] AS [Container Comment],
       ML.[Item_Type]
FROM dbo.T_Material_Log ML
     LEFT OUTER JOIN dbo.T_Users U
       ON ML.User_PRN = U.U_PRN
     LEFT OUTER JOIN dbo.T_Material_Containers TMC
       ON ML.Item = TMC.Tag


GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Log_List_Report] TO [DDL_Viewer] AS [dbo]
GO
