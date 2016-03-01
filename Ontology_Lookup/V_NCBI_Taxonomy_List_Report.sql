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
       ParentNodeName.Name AS Parent_Name,
       [Nodes].EMBL_Code,
       Division.Division_Name AS Division,
       GenCode.Genetic_Code_Name,
       GenCodeMit.Genetic_Code_Name AS Mito_GenCodeName,
       IsNull(SynonymStats.Synonyms, 0) AS Synonyms,
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
     LEFT OUTER JOIN ( SELECT PrimaryName.Tax_ID,
                              Count(*) AS Synonyms
                       FROM T_NCBI_Taxonomy_Names NameList
                            INNER JOIN T_NCBI_Taxonomy_Names PrimaryName
                              ON NameList.Tax_ID = PrimaryName.Tax_ID 
                                 AND
                                 PrimaryName.Name_Class = 'scientific name'
                            INNER JOIN T_NCBI_Taxonomy_Name_Class NameClass
                              ON NameList.Name_Class = NameClass.Name_Class
                       WHERE (NameClass.Sort_Weight BETWEEN 2 AND 19)
                       GROUP BY PrimaryName.Tax_ID ) SynonymStats
       ON [Nodes].Tax_ID = SynonymStats.Tax_ID
WHERE (NodeNames.Name_Class = 'scientific name')


GO
