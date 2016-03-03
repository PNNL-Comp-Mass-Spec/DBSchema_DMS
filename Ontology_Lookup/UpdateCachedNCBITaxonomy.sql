/****** Object:  StoredProcedure [dbo].[UpdateCachedNCBITaxonomy] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.UpdateCachedNCBITaxonomy
/****************************************************
**
**	Desc: Updates dataset in T_NCBI_Taxonomy_Cached
**
**	Auth:	mem
**	Date:	03/01/2016 mem - Initial version
**    
*****************************************************/
(
	@DeleteExtras tinyint = 1,
	@infoOnly tinyint = 1
)
As
	
	set nocount on

	Declare @myError int
	Declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Set @DeleteExtras = IsNull(@DeleteExtras, 1)
	Set @infoOnly = IsNull(@infoOnly, 1)
	
	---------------------------------------------------
	-- Update T_NCBI_Taxonomy_Cached
	---------------------------------------------------

	Declare @tableName varchar(128)
	Set @tableName = 'T_NCBI_Taxonomy_Cached'
	 
	MERGE [dbo].[T_NCBI_Taxonomy_Cached] AS t
	USING (
		SELECT [Nodes].Tax_ID,
		       NodeNames.Name,
		       [Nodes].Rank,
		       [Nodes].Parent_Tax_ID,
		       ISNULL(SynonymStats.Synonyms, 0) AS Synonyms
		FROM T_NCBI_Taxonomy_Names NodeNames
		     INNER JOIN T_NCBI_Taxonomy_Nodes [Nodes]
		       ON NodeNames.Tax_ID = [Nodes].Tax_ID
		     LEFT OUTER JOIN ( SELECT PrimaryName.Tax_ID,
		                              COUNT(*) AS Synonyms
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
	) as s
	ON ( t.[Tax_ID] = s.[Tax_ID])
	WHEN MATCHED AND (
		t.[Name] <> s.[Name] OR
		t.[Rank] <> s.[Rank] OR
		t.[Parent_Tax_ID] <> s.[Parent_Tax_ID] OR
		t.[Synonyms] <> s.[Synonyms]
		)
	THEN UPDATE SET 
		[Name] = s.[Name],
		[Rank] = s.[Rank],
		[Parent_Tax_ID] = s.[Parent_Tax_ID],
		[Synonyms] = s.[Synonyms]
	WHEN NOT MATCHED BY TARGET THEN
		INSERT([Tax_ID], [Name], [Rank], [Parent_Tax_ID], [Synonyms])
		VALUES(s.[Tax_ID], s.[Name], s.[Rank], s.[Parent_Tax_ID], s.[Synonyms])
	WHEN NOT MATCHED BY SOURCE And @DeleteExtras <> 0 THEN DELETE;
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount


	---------------------------------------------------
	-- Update the Synonym_List column
	---------------------------------------------------

	MERGE [dbo].[T_NCBI_Taxonomy_Cached] AS t
	USING (
		SELECT Tax_ID,
		       dbo.GetTaxIDSynonymList(TaxIDs.Tax_ID) AS Synonym_List
		FROM T_NCBI_Taxonomy_Cached AS TaxIDs
		WHERE TaxIDs.Synonyms > 0
	) as s
	ON ( t.[Tax_ID] = s.[Tax_ID])
	WHEN MATCHED AND (
		ISNULL( NULLIF(t.[Synonym_List], s.[Synonym_List]),
            NULLIF(s.[Synonym_List], t.[Synonym_List])) IS NOT NULL
		)
	THEN UPDATE SET 
		Synonym_List = s.[Synonym_List];
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount


	---------------------------------------------------
	-- Clear the Synonym_List columnn for entries with Synonyms = 0
	---------------------------------------------------

	UPDATE T_NCBI_Taxonomy_Cached
	Set Synonym_List = ''
	WHERE Synonyms = 0 And (Synonym_List is null or Synonym_List <> '')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	
Done:
	return 0


GO
