/****** Object:  View [dbo].[V_Helper_NCBI_Taxonomy_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Helper_NCBI_Taxonomy_Report]
AS
SELECT Nodes.tax_id,
       NodeNames.name,
       Nodes.rank,
       Nodes.parent_tax_id,
       dbo.get_taxid_child_count(Nodes.Tax_ID) AS children,
       ParentNodeName.Name AS parent_name,
       Division.Division_Name AS division
FROM T_NCBI_Taxonomy_Names NodeNames
     INNER JOIN T_NCBI_Taxonomy_Nodes Nodes
       ON NodeNames.Tax_ID = Nodes.Tax_ID
     INNER JOIN T_NCBI_Taxonomy_Division Division
       ON Nodes.Division_ID = Division.Division_ID
     INNER JOIN T_NCBI_Taxonomy_Nodes ParentNode
       ON Nodes.Parent_Tax_ID = ParentNode.Tax_ID
     INNER JOIN T_NCBI_Taxonomy_Names ParentNodeName
       ON ParentNode.Tax_ID = ParentNodeName.Tax_ID AND
          ParentNodeName.Name_Class = 'scientific name'
     LEFT OUTER JOIN T_NCBI_Taxonomy_Cached AS SynonymStats
       ON Nodes.Tax_ID = SynonymStats.Tax_ID
WHERE (NodeNames.Name_Class = 'scientific name') AND
      NOT Nodes.Rank IN ('class', 'infraclass', 'infraorder', 'kingdom', 'order', 'parvorder',
      'phylum', 'subclass', 'subkingdom', 'suborder', 'subphylum', 'subtribe',
      'superclass', 'superfamily', 'superkingdom', 'superorder', 'superphylum', 'tribe')

GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_NCBI_Taxonomy_Report] TO [DDL_Viewer] AS [dbo]
GO
