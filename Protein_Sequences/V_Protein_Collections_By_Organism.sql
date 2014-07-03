/****** Object:  View [dbo].[V_Protein_Collections_By_Organism] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Protein_Collections_By_Organism]
AS
SELECT DISTINCT VPC.Protein_Collection_ID,
                VPC.Display,
                VPC.Description,
                PC.Collection_State_ID,
                PC.Collection_Type_ID,
                PC.NumProteins,
                PC.Authentication_Hash,
                VPC.FileName,
                OrgXref.Organism_ID,
                VPC.Primary_Annotation_Type_ID AS Authority_ID,
                OrgPicker.Short_Name AS Organism_Name,
                VPC.Contents_Encrypted AS Contents_Encrypted
FROM T_Protein_Collections PC
     INNER JOIN T_Collection_Organism_Xref OrgXref
       ON PC.Protein_Collection_ID = OrgXref.Protein_Collection_ID
     INNER JOIN V_Protein_Collections VPC
       ON PC.Protein_Collection_ID = VPC.Protein_Collection_ID
     INNER JOIN V_Organism_Picker OrgPicker
       ON OrgXref.Organism_ID = OrgPicker.ID



GO
GRANT SELECT ON [dbo].[V_Protein_Collections_By_Organism] TO [pnl\d3l243] AS [dbo]
GO
