/****** Object:  View [dbo].[V_Separation_Group_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Separation_Group_Entry]
AS
SELECT SG.Sep_Group AS separation_group,
       SG.comment,
       SG.active,
       SG.sample_prep_visible,
       SG.fraction_count
FROM T_Separation_Group SG


GO
GRANT VIEW DEFINITION ON [dbo].[V_Separation_Group_Entry] TO [DDL_Viewer] AS [dbo]
GO
