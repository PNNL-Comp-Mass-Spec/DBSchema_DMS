/****** Object:  StoredProcedure [dbo].[add_update_protein_collection] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_protein_collection]
/****************************************************
**
**  Desc: Adds a new protein collection entry
**
**  Return values: The new Protein Collection ID if success; otherwise, 0
**
**  Auth:   kja
**  Date:   09/29/2004
**          11/23/2005 KJA
**          09/13/2007 mem - Now using get_protein_collection_id instead of @@Identity to lookup the collection ID
**          01/18/2010 mem - Now validating that @@collectionName does not contain a space
**                         - Now returns 0 if an error occurs; returns the protein collection ID if no errors
**          11/24/2015 mem - Added @collectionSource
**          06/26/2019 mem - Add comments and convert tabs to spaces
**          01/20/2020 mem - Replace < and > with ( and ) in the source and description
**          07/27/2022 mem - Switch from FileName to Collection_Name
**                         - Rename argument @fileName to @collectionName
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**          08/21/2023 mem - Assure that text parameters are not null and validate mode
**
*****************************************************/
(
    @collectionName varchar(128),         -- Protein collection name, which is typically the original FASTA file name but without the file extension
    @description varchar(900),
    @collectionSource varchar(900) = '',
    @collectionType int = 1,
    @collectionState int,
    @primaryAnnotationTypeId int,
    @numProteins int = 0,
    @numResidues int = 0,
    @active int = 1,
    @mode varchar(12) = 'add',
    @message varchar(512) output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @collectionName   = LTrim(RTrim(Coalesce(@collectionName, '')));
    Set @description      = LTrim(RTrim(Coalesce(@description, '')));
    Set @collectionSource = LTrim(RTrim(Coalesce(@collectionSource, '')));

    Set @mode = Lower(LTrim(RTrim(Coalesce(@mode, ''))));

    If LEN(@collectionName) < 1
    Begin
        Set @myError = 51000
        Set @message = '@collectionName was blank'
        RAISERROR (@message, 10, 1)
    End
    
    If @myError = 0 And Not @mode In ('add', 'update')
    Begin
        Set @myError = 51001
        Set @message = 'Invalid mode; should be "add" or "update"'
        RAISERROR (@message, 10, 1)
    End

    -- Make sure @collectionName does not contain a space

    If @myError = 0 And @collectionName Like '% %'
    Begin
        Set @myError = 51002
        Set @message = 'Protein collection name contains a space: "' + @collectionName + '"'
        RAISERROR (@message, 10, 1)
    End

    If @myError <> 0
    Begin
        -- Return zero, since we did not create a protein collection
        RETURN 0
    End

    -- Make sure the Description and Source do not have text surrounded by < and >, since web browsers will treat that as an HTML tag
    Set @description =      REPLACE(REPLACE(Coalesce(@description,      ''), '<', '('), '>', ')')
    Set @collectionSource = REPLACE(REPLACE(Coalesce(@collectionSource, ''), '<', '('), '>', ')')

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    Declare @collectionID Int = 0

    execute @collectionID = get_protein_collection_id @collectionName

    If @collectionID > 0 and @mode = 'add'
    Begin
        -- Collection already exists; auto-change @mode to 'update'
        set @mode = 'update'
    End

    If @collectionID = 0 and @mode = 'update'
    Begin
        -- Collection not found; auto-change @mode to 'add'
        set @mode = 'add'
    End

    -- Uncomment to debug
    --
    -- set @message = 'mode ' + @mode + ', collection '+ @collectionName
    -- exec post_log_entry 'Debug', @message, 'add_update_protein_collection'
    -- set @message=''

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    declare @transName varchar(32) = 'AddProteinCollectionEntry'
    Begin transaction @transName

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    If @mode = 'add'
    Begin

        INSERT INTO T_Protein_Collections (
            Collection_Name,
            Description,
            Source,
            Collection_Type_ID,
            Collection_State_ID,
            Primary_Annotation_Type_ID,
            NumProteins,
            NumResidues,
            DateCreated,
            DateModified,
            Uploaded_By
        ) VALUES (
            @collectionName,
            @description,
            @collectionSource,
            @collectionType,
            @collectionState,
            @primaryAnnotationTypeId,
            @numProteins,
            @numResidues,
            GETDATE(),
            GETDATE(),
            SYSTEM_USER
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            rollback transaction @transName
            set @message = 'Insert operation failed: "' + @collectionName + '"'
            RAISERROR (@message, 10, 1)

            -- Return zero, since we did not create a protein collection
            RETURN 0
        End

--            INSERT INTO T_Annotation_Groups (
--            Protein_Collection_ID,
--            Annotation_Group,
--            Annotation_Type_ID
--            ) VALUES (
--            @collectionID,
--            0,
--            @primaryAnnotationTypeId
--            )

    End

    If @mode = 'update'
    Begin

        UPDATE T_Protein_Collections
        SET
            Description = @description,
            Source = Case When @collectionSource = '' and IsNull(Source, '') <> '' Then Source Else @collectionSource End,
            Collection_State_ID = @collectionState,
            Collection_Type_ID = @collectionType,
            NumProteins = @numProteins,
            NumResidues = @numResidues,
            DateModified = GETDATE()
        WHERE Collection_Name = @collectionName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            rollback transaction @transName
            set @message = 'Update operation failed: "' + @collectionName + '"'
            RAISERROR (@message, 10, 1)

            -- Return zero, since we did not create a protein collection
            RETURN 0
        End
    End

    commit transaction @transName

    -- Lookup the collection ID
    execute @collectionID = get_protein_collection_id @collectionName

    If @mode = 'add'
    Begin
        set @transName = 'AddProteinCollectionEntry'
        Begin transaction @transName

        INSERT INTO T_Annotation_Groups (
            Protein_Collection_ID,
            Annotation_Group,
            Annotation_Type_ID
        ) VALUES (
            @collectionID,
            0,
            @primaryAnnotationTypeId
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            rollback transaction @transName
            set @message = 'Update operation failed: "' + @collectionName + '"'
            RAISERROR (@message, 10, 1)

            -- Return zero, since we did not create a protein collection
            RETURN 0
        End

        commit transaction @transName
    End

    RETURN @collectionID

GO
GRANT EXECUTE ON [dbo].[add_update_protein_collection] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
