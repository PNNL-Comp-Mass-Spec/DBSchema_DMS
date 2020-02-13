/****** Object:  View [dbo].[V_Archived_Output_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Archived_Output_Files]
AS
SELECT AOF.Archived_File_ID,
       XRef.Protein_Collection_ID,
       AOF.Authentication_Hash,
       AOF.Archived_File_Path,
       FS.Archived_File_State,
       FT.File_Type_Name AS Archived_File_Type,
       AOF.Archived_File_Creation_Date,
       AOF.File_Modification_Date,
       AOF.Creation_Options,
       AOF.Filesize / 1024.0 / 1024.0 As File_Size_MB
FROM dbo.T_Archived_Output_Files AOF
     INNER JOIN dbo.T_Archived_Output_File_Collections_XRef XRef
       ON AOF.Archived_File_ID = XRef.Archived_File_ID
     INNER JOIN dbo.T_Archived_File_States FS
       ON AOF.Archived_File_State_ID = FS.Archived_File_State_ID
     INNER JOIN dbo.T_Archived_File_Types FT
       ON AOF.Archived_File_Type_ID = FT.Archived_File_Type_ID


GO
