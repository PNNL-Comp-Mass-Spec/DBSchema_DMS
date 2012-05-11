/****** Object:  View [dbo].[V_Archived_Output_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Archived_Output_Files
AS
SELECT     dbo.T_Archived_Output_Files.Archived_File_ID, dbo.T_Archived_Output_File_Collections_XRef.Protein_Collection_ID, 
                      dbo.T_Archived_Output_Files.Authentication_Hash, dbo.T_Archived_Output_Files.Archived_File_Path, dbo.T_Archived_File_States.Archived_File_State, 
                      dbo.T_Archived_File_Types.File_Type_Name AS Archived_File_Type, dbo.T_Archived_Output_Files.Archived_File_Creation_Date, 
                      dbo.T_Archived_Output_Files.File_Modification_Date, dbo.T_Archived_Output_Files.Creation_Options
FROM         dbo.T_Archived_Output_Files INNER JOIN
                      dbo.T_Archived_Output_File_Collections_XRef ON 
                      dbo.T_Archived_Output_Files.Archived_File_ID = dbo.T_Archived_Output_File_Collections_XRef.Archived_File_ID INNER JOIN
                      dbo.T_Archived_File_States ON dbo.T_Archived_Output_Files.Archived_File_State_ID = dbo.T_Archived_File_States.Archived_File_State_ID INNER JOIN
                      dbo.T_Archived_File_Types ON dbo.T_Archived_Output_Files.Archived_File_Type_ID = dbo.T_Archived_File_Types.Archived_File_Type_ID

GO
