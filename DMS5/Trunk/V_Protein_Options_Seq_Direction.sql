/****** Object:  View [dbo].[V_Protein_Options_Seq_Direction] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Protein_Options_Seq_Direction
AS
SELECT String_Element AS ex,
       Display_Value AS val
FROM ProteinSeqs.Protein_Sequences.dbo.V_Creation_String_Lookup CSL
WHERE (Keyword = 'seq_direction')

GO
