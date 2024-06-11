/****** Object:  StoredProcedure [dbo].[add_new_terms_default_ontologies] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_new_terms_default_ontologies]
/****************************************************
**
**  Desc:
**      Add new ontology terms to the ontology-specific tables for the default ontologies:
**      CL, GO, MI (PSI_MI), MOD (PSI_Mod), PRIDE, and DOID
**
**      Calls function add_new_terms, which pulls data from t_ontology, t_term, and t_term_relationship (using v_term_lineage)
**      and updates the ontology-specific table (t_cv_cl, t_cv_go, t_cv_mi, t_cv_mod, t_cv_pride, or t_cv_doid)
**
**      Note that BTO, ENVO, MS, and NEWT have dedicated functions for adding new terms
**      - add_new_bto_terms
**      - add_new_envo_terms
**      - add_new_ms_terms
**      - add_new_newt_terms
**
**  Arguments:
**    _infoOnly       When true, preview updates
**    _previewSql     When true, preview the SQL (but do not execute it)
**
**  Usage:
**      EXEC add_new_terms_default_ontologies @infoOnly = 0, @previewSql = 0;
**
**  Auth:   mem
**  Date:   05/13/2013 mem - Initial Version
**          12/04/2013 mem - Added CL
**          03/17/2014 mem - Added DOID (disease ontology)
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          06/09/2024 mem - No longer call add_new_terms for BTO, MS, or NEWT; instead, use function add_new_newt_terms
**
*****************************************************/
(
    @infoOnly tinyint = 0,
    @previewSql tinyint= 0
)
AS
    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Call add_new_terms for the ontologies of interest
    -- This will pull data from t_ontology, t_term, and 
    -- t_term_relationship (using v_term_lineage) and update
    -- the ontology-specific table (t_cv_cl, t_cv_go, etc.)
    ---------------------------------------------------

    -- Note that BTO, ENVO, MS, and NEWT have dedicated functions for adding new terms

    exec @myError = add_new_terms @OntologyName='CL',    @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql
    exec @myError = add_new_terms @OntologyName='GO',    @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql
    exec @myError = add_new_terms @OntologyName='MI',    @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql       -- PSI_MI
    exec @myError = add_new_terms @OntologyName='MOD',   @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql       -- PSI_Mod
    exec @myError = add_new_terms @OntologyName='PRIDE', @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql
    exec @myError = add_new_terms @OntologyName='DOID',  @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql

    -- Deprecated, instead use add_new_bto_terms, add_new_ms_terms, or add_new_newt_terms
    -- exec @myError = add_new_terms @OntologyName='BTO',   @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql
    -- exec @myError = add_new_terms @OntologyName='MS',    @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql       -- PSI_MS
    -- exec @myError = add_new_terms @OntologyName='NEWT',  @InfoOnly=@InfoOnly, @PreviewSql=@PreviewSql


    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_new_terms_default_ontologies] TO [DDL_Viewer] AS [dbo]
GO
