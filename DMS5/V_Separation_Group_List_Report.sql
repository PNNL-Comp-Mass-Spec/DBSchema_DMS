/****** Object:  View [dbo].[V_Separation_Group_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Separation_Group_List_Report] as
SELECT Sep_Group AS Separation_Group,
       Comment,
       Active,
	   Sample_Prep_Visible
FROM T_Separation_Group


GO
GRANT VIEW DEFINITION ON [dbo].[V_Separation_Group_List_Report] TO [DDL_Viewer] AS [dbo]
GO
