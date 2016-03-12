/****** Object:  View [dbo].[V_Param_File_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Param_File_Report
AS
SELECT     Param_File_Name AS param_file_name, Param_File_Description AS description, ISNULL(Job_Usage_Count, 0) AS job_count, Param_File_ID AS param_file_id, 
                      Param_File_Type_ID AS param_file_type_id, Valid AS is_valid, Date_Created AS date_created
FROM         dbo.T_Param_Files AS PF

GO
GRANT VIEW DEFINITION ON [dbo].[V_Param_File_Report] TO [PNL\D3M578] AS [dbo]
GO
