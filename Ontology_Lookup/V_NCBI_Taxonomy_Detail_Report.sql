/****** Object:  View [dbo].[V_NCBI_Taxonomy_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- List Report
CREATE VIEW [dbo].[V_NCBI_Taxonomy_Detail_Report]
AS
SELECT [Nodes].Tax_ID,
       NodeNames.Name,
	   NodeNames.Unique_Name, 
       Nodes.Comments,
       [Nodes].[Rank],
       [Nodes].Parent_Tax_ID,
       ParentNodeName.Name AS Parent_Name,
       [Nodes].EMBL_Code,
       Division.Division_Name AS Division,
       [Nodes].Genetic_Code_ID,
       GenCode.Genetic_Code_Name,
       [Nodes].Mito_Genetic_Code_ID,
       GenCodeMit.Genetic_Code_Name AS Mito_GenCodeName,
       [Nodes].GenBank_Hidden
FROM T_NCBI_Taxonomy_Names NodeNames
     INNER JOIN T_NCBI_Taxonomy_Nodes [Nodes]
       ON NodeNames.Tax_ID = [Nodes].Tax_ID
     INNER JOIN T_NCBI_Taxonomy_Division Division
       ON [Nodes].Division_ID = Division.Division_ID
     INNER JOIN T_NCBI_Taxonomy_GenCode GenCode
       ON [Nodes].Genetic_Code_ID = GenCode.Genetic_Code_ID
     INNER JOIN T_NCBI_Taxonomy_Nodes ParentNode
       ON [Nodes].Parent_Tax_ID = ParentNode.Tax_ID
     INNER JOIN T_NCBI_Taxonomy_Names ParentNodeName
       ON ParentNode.Tax_ID = ParentNodeName.Tax_ID AND
          ParentNodeName.Name_Class = 'scientific name'
     INNER JOIN T_NCBI_Taxonomy_GenCode GenCodeMit
       ON [Nodes].Mito_Genetic_Code_ID = GenCodeMit.Genetic_Code_ID
WHERE (NodeNames.Name_Class = 'scientific name')



GO
