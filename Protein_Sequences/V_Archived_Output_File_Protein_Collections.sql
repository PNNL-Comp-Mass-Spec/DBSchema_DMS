/****** Object:  View [dbo].[V_Archived_Output_File_Protein_Collections] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Archived_Output_File_Protein_Collections
AS
SELECT AOF.Archived_File_ID, AOF.Archived_File_Path, 
    dbo.T_Archived_File_Types.File_Type_Name, 
    dbo.T_Archived_File_States.Archived_File_State, 
    LookupQ.Protein_Collection_Count, 
    AOFC.Protein_Collection_ID, PC.FileName
FROM dbo.T_Archived_Output_Files AOF INNER JOIN
        (SELECT AOF.Archived_File_ID, COUNT(*) 
           AS Protein_Collection_Count
      FROM dbo.T_Archived_Output_Files AOF INNER JOIN
           dbo.T_Archived_Output_File_Collections_XRef AOFC ON
            AOF.Archived_File_ID = AOFC.Archived_File_ID
      GROUP BY AOF.Archived_File_ID) LookupQ ON 
    AOF.Archived_File_ID = LookupQ.Archived_File_ID INNER JOIN
    dbo.T_Archived_Output_File_Collections_XRef AOFC ON 
    AOF.Archived_File_ID = AOFC.Archived_File_ID INNER JOIN
    dbo.T_Protein_Collections PC ON 
    AOFC.Protein_Collection_ID = PC.Protein_Collection_ID INNER JOIN
    dbo.T_Archived_File_Types ON 
    AOF.Archived_File_Type_ID = dbo.T_Archived_File_Types.Archived_File_Type_ID
     INNER JOIN
    dbo.T_Archived_File_States ON 
    AOF.Archived_File_State_ID = dbo.T_Archived_File_States.Archived_File_State_ID

GO
