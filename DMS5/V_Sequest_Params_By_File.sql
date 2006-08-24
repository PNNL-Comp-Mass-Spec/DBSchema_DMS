/****** Object:  View [dbo].[V_Sequest_Params_By_File] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Sequest_Params_By_File
AS
SELECT     TOP 100 PERCENT dbo.T_Param_Files.Param_File_ID, dbo.T_Param_Files.Param_File_Name, dbo.T_Param_Entries.Entry_Sequence_Order, 
                      dbo.T_Param_Entries.Entry_Type, dbo.T_Param_Entries.Entry_Specifier, dbo.T_Param_Entries.Entry_Value
FROM         dbo.T_Param_Files INNER JOIN
                      dbo.T_Param_Entries ON dbo.T_Param_Files.Param_File_ID = dbo.T_Param_Entries.Param_File_ID
ORDER BY dbo.T_Param_Files.Param_File_Name, dbo.T_Param_Entries.Entry_Sequence_Order

GO
