/****** Object:  View [dbo].[V_Param_File_Type_PickList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Param_File_Type_PickList]
AS
SELECT PFT.Param_File_Type_ID,
       PFT.Param_File_Type,
	   CASE WHEN PFT.Param_File_Type = Tool.AJT_toolName OR
                 Tool.AJT_toolName IN ('(none)', 'MASIC_Finnigan', 'SMAQC_MSMS') 
            THEN PFT.Param_File_Type
            ELSE PFT.Param_File_Type + ' (' + Tool.AJT_toolName + ')'
       END AS Param_File_Type_Ex
FROM T_Param_File_Types PFT
     INNER JOIN T_Analysis_Tool Tool
       ON PFT.Primary_Tool_ID = Tool.AJT_toolID
WHERE PFT.Param_File_Type_ID > 1


GO
GRANT VIEW DEFINITION ON [dbo].[V_Param_File_Type_PickList] TO [DDL_Viewer] AS [dbo]
GO
