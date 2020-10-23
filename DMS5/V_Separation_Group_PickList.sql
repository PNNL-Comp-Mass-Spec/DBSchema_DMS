/****** Object:  View [dbo].[V_Separation_Group_PickList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Separation_Group_PickList] AS
SELECT Sep_Group, Sample_Prep_Visible, Fraction_Count
FROM T_Separation_Group 
WHERE Active > 0


GO
