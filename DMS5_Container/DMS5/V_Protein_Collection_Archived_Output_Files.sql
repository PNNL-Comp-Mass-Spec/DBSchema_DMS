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
       Creation_Options
FROM PROTEINSEQS.Protein_Sequences.dbo.V_Archived_Output_Files AS AOF


GO
GRANT VIEW DEFINITION ON [dbo].[V_Protein_Collection_Archived_Output_Files] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Protein_Collection_Archived_Output_Files] TO [PNL\D3M580] AS [dbo]
GO
