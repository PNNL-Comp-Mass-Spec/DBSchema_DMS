/****** Object:  View [dbo].[V_NCBI_Taxonomy_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_NCBI_Taxonomy_List_Report]
AS
SELECT [Nodes].Tax_ID,
       NodeNames.Name,
       [Nodes].[Rank],
       [Nodes].Parent_Tax_ID,
	   dbo.GetTaxIDChildCount([Nodes].Tax_ID) AS Children,
       ParentNodeName.Name AS Parent_Name,
       [Nodes].EMBL_Code,
       Division.Division_Name AS Division,
       GenCode.Genetic_Code_Name,
       GenCodeMit.Genetic_Code_Name AS Mito_GenCodeName,
       SynonymStats.Synonyms,
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
     LEFT OUTER JOIN T_NCBI_Taxonomy_Cached AS SynonymStats
       ON [Nodes].Tax_ID = SynonymStats.Tax_ID
WHERE (NodeNames.Name_Class = 'scientific name')




GO
GRANT VIEW DEFINITION ON [dbo].[V_NCBI_Taxonomy_List_Report] TO [DDL_Viewer] AS [dbo]
GO
