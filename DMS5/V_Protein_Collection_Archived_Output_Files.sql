/****** Object:  View [dbo].[V_Protein_Collection_Archived_Output_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Collection_Archived_Output_Files]
AS
SELECT Archived_File_ID,
       Protein_Collection_ID,
       Authentication_Hash,
       Archived_File_Path,
       Archived_File_State,
       Archived_File_Type,
       Archived_File_Creation_Date,
       File_Modification_Date,
       Creation_Options,
       File_Size_MB
FROM S_ProteinSeqs_V_Archived_Output_Files

GO
GRANT VIEW DEFINITION ON [dbo].[V_Protein_Collection_Archived_Output_Files] TO [DDL_Viewer] AS [dbo]
GO
