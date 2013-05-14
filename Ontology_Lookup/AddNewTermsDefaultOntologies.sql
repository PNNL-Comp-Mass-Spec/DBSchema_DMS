/****** Object:  StoredProcedure [dbo].[AddNewTermsDefaultOntologies] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddNewTermsDefaultOntologies
/****************************************************
**
**	Desc: 
**		Adds new ontology terms to the ontology-specific tables for the default ontologies:
**		BTO, GO, PSI_MI, PSI_Mod, PSI_MS, PRIDE, and NeWT
**
**	Auth:	mem
**	Date:	05/13/2013 mem - Initial Version
**
*****************************************************/
(
	@InfoOnly tinyint = 0,
	@PreviewSql tinyint= 0
)
AS
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	---------------------------------------------------
	-- Validate the ontology name
	---------------------------------------------------
	--

	exec @myError = AddNewTerms @OntologyName='BTO',   @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql
	exec @myError = AddNewTerms @OntologyName='GO',    @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql
	exec @myError = AddNewTerms @OntologyName='MI',    @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql		-- PSI_MI
	exec @myError = AddNewTerms @OntologyName='MOD',   @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql		-- PSI_Mod
	exec @myError = AddNewTerms @OntologyName='MS',    @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql		-- PSI_MS
	exec @myError = AddNewTerms @OntologyName='PRIDE', @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql
	exec @myError = AddNewTerms @OntologyName='NEWT',  @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql

	---------------------------------------------------
	-- exit
	---------------------------------------------------
	--
Done:
	return @myError
GO
