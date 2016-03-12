/****** Object:  View [dbo].[V_Acceptable_Param_Entries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Acceptable_Param_Entries
AS
SELECT     dbo.T_Acceptable_Param_Entries.Parameter_Name, dbo.T_Acceptable_Param_Entries.Canonical_Name, dbo.T_Acceptable_Param_Entries.Parameter_Category, 
                      dbo.T_Acceptable_Param_Entries.Default_Value, dbo.T_Acceptable_Param_Entry_Types.Param_Entry_Type_Name, 
                      dbo.T_Acceptable_Param_Entry_Types.Formatting_String, dbo.T_Acceptable_Param_Entries.Picker_Items_List, dbo.T_Acceptable_Param_Entries.Output_Order, 
                      dbo.T_Analysis_Tool.AJT_toolName AS Analysis_Job_Toolname, dbo.T_Analysis_Tool.AJT_paramFileType AS Param_File_Type_ID, 
                      dbo.T_Acceptable_Param_Entries.First_Applicable_Version, dbo.T_Acceptable_Param_Entries.Last_Applicable_Version, 
                      dbo.T_Acceptable_Param_Entry_Types.Param_Entry_Type_ID, dbo.T_Acceptable_Param_Entries.Display_Name
FROM         dbo.T_Acceptable_Param_Entries INNER JOIN
                      dbo.T_Acceptable_Param_Entry_Types ON 
                      dbo.T_Acceptable_Param_Entries.Param_Entry_Type_ID = dbo.T_Acceptable_Param_Entry_Types.Param_Entry_Type_ID INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Acceptable_Param_Entries.Analysis_Tool_ID = dbo.T_Analysis_Tool.AJT_toolID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Acceptable_Param_Entries] TO [PNL\D3M578] AS [dbo]
GO
