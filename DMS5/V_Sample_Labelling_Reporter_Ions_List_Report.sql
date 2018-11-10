/****** Object:  View [dbo].[V_Sample_Labelling_Reporter_Ions_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Labelling_Reporter_Ions_List_Report]
As
SELECT Label,
       Channel,
       Tag_Name,
       MASIC_Name,
       Reporter_Ion_Mz
FROM T_Sample_Labelling_Reporter_Ions


GO
