/****** Object:  View [dbo].[V_Separation_Group_PickList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Separation_Group_PickList] as
SELECT Sep_Group, Sample_Prep_Visible
FROM T_Separation_Group 
WHERE Active > 0


GO
