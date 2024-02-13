/****** Object:  View [dbo].[V_Material_Log_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Material_Log_List_Report]
AS
SELECT ML.id,
       ML.entered AS date,
       ML.Type_Name_Cached AS type,
       ML.item,
       ML.Initial_State AS initial,
       ML.Final_State AS final,
       U.Name_with_PRN AS [user],
       ML.comment,
       TMC.Comment AS container_comment,
       ML.item_type
FROM dbo.T_Material_Log ML
     LEFT OUTER JOIN dbo.T_Users U
       ON ML.User_PRN = U.U_PRN
     LEFT OUTER JOIN dbo.T_Material_Containers TMC
       ON ML.Item = TMC.Tag

GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Log_List_Report] TO [DDL_Viewer] AS [dbo]
GO
