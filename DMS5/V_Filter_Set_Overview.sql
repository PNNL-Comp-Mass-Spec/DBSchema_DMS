/****** Object:  View [dbo].[V_Filter_Set_Overview] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Filter_Set_Overview]
AS
SELECT FST.Filter_Type_ID,
       FST.Filter_Type_Name,
       FS.Filter_Set_ID,
       FS.Filter_Set_Name,
       FS.Filter_Set_Description       
FROM dbo.T_Filter_Sets FS
     INNER JOIN dbo.T_Filter_Set_Types FST
       ON FS.Filter_Type_ID = FST.Filter_Type_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Filter_Set_Overview] TO [PNL\D3M578] AS [dbo]
GO
