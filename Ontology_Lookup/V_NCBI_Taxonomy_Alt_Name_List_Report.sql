/****** Object:  View [dbo].[V_NCBI_Taxonomy_Alt_Name_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_NCBI_Taxonomy_Alt_Name_List_Report]
AS
SELECT PrimaryName.tax_id,
       PrimaryName.Name AS scientific_name,
       NameList.Name_Class AS synonym_type,
       NameList.Name AS synonym,
       Nodes.rank,
       Nodes.parent_tax_id,
       ParentNodeName.Name AS parent_name,
       Division.Division_Name AS division
FROM T_NCBI_Taxonomy_Names NameList
     INNER JOIN T_NCBI_Taxonomy_Names PrimaryName
       ON NameList.Tax_ID = PrimaryName.Tax_ID AND
          PrimaryName.Name_Class = 'scientific name'
     INNER JOIN T_NCBI_Taxonomy_Name_Class NameClass
       ON NameList.Name_Class = NameClass.Name_Class
     INNER JOIN T_NCBI_Taxonomy_Nodes Nodes
       ON PrimaryName.Tax_ID = Nodes.Tax_ID
     INNER JOIN T_NCBI_Taxonomy_Names ParentNodeName
       ON Nodes.Parent_Tax_ID = ParentNodeName.Tax_ID AND
          ParentNodeName.Name_Class = 'scientific name'
     INNER JOIN T_NCBI_Taxonomy_Division Division
       ON Nodes.Division_ID = Division.Division_ID
WHERE (NameClass.Sort_Weight BETWEEN 2 AND 19)


GO
GRANT VIEW DEFINITION ON [dbo].[V_NCBI_Taxonomy_Alt_Name_List_Report] TO [DDL_Viewer] AS [dbo]
GO
