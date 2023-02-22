/****** Object:  StoredProcedure [dbo].[add_new_terms_default_ontologies] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_new_terms_default_ontologies]
/****************************************************
**
**  Desc:
**      Adds new ontology terms to the ontology-specific tables for the default ontologies:
**      BTO, GO, PSI_MI, PSI_Mod, PSI_MS, PRIDE, and NeWT
**
**  Auth:   mem
**  Date:   05/13/2013 mem - Initial Version
**          12/04/2013 mem - Added CL
**          03/17/2014 mem - Added DOID (disease ontology)
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @infoOnly tinyint = 0,
    @previewSql tinyint= 0
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

    exec @myError = add_new_terms @OntologyName='BTO',   @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql
    exec @myError = add_new_terms @OntologyName='CL',    @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql
    exec @myError = add_new_terms @OntologyName='GO',    @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql
    exec @myError = add_new_terms @OntologyName='MI',    @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql       -- PSI_MI
    exec @myError = add_new_terms @OntologyName='MOD',   @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql       -- PSI_Mod
    exec @myError = add_new_terms @OntologyName='MS',    @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql       -- PSI_MS
    exec @myError = add_new_terms @OntologyName='PRIDE', @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql
    exec @myError = add_new_terms @OntologyName='NEWT',  @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql
    exec @myError = add_new_terms @OntologyName='DOID',  @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql

    ---------------------------------------------------
    -- exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_new_terms_default_ontologies] TO [DDL_Viewer] AS [dbo]
GO
