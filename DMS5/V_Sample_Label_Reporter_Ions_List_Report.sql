/****** Object:  View [dbo].[V_Sample_Label_Reporter_Ions_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Label_Reporter_Ions_List_Report]
As
SELECT label,
       channel,
       tag_name,
       masic_name,
       reporter_ion_mz
FROM T_Sample_Labelling_Reporter_Ions


GO
