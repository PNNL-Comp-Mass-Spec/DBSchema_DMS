/****** Object:  StoredProcedure [dbo].[AddUpdateProteinCollection] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateProteinCollection]
/****************************************************
**
**  Desc: Adds a new protein collection entry
**
**  Return values: The new Protein Collection ID if success; otherwise, 0
**
**  Auth:   kja
**  Date:   09/29/2004
**          11/23/2005 KJA
**          09/13/2007 mem - Now using GetProteinCollectionID instead of @@Identity to lookup the collection ID
**          01/18/2010 mem - Now validating that @@collectionName does not contain a space
**                         - Now returns 0 if an error occurs; returns the protein collection ID if no errors
**          11/24/2015 mem - Added @collectionSource
**          06/26/2019 mem - Add comments and convert tabs to spaces
**          01/20/2020 mem - Replace < and > with ( and ) in the source and description
**          07/27/2022 mem - Switch from FileName to Collection_Name
**                         - Rename argument @fileName to @collectionName
**    
*****************************************************/
(
    @collectionName varchar(128),         -- Protein collection name, which is typically the original FASTA file name but without the file extension
    @description varchar(900),
    @collectionSource varchar(900) = '',
    @collection_type int = 1,
    @collection_state int,
    @primary_annotation_type_id int,
    @numProteins int = 0,
    @numResidues int = 0,
    @active int = 1,
    @mode varchar(12) = 'add',
    @message varchar(512) output
)
As
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    set @myError = 0

    if LEN(@collectionName) < 1
    begin
        set @myError = 51000
        Set @message = '@collectionName was blank'
        RAISERROR (@message, 10, 1)
    end

    -- Make sure @@collectionName does not contain a space
    Set @collectionName = RTrim(@collectionName)
    
    If @collectionName Like '% %'
    begin
        set @myError = 51001
        Set @message = 'Protein collection name contains a space: "' + @collectionName + '"'
        RAISERROR (@message, 10, 1)
    end
    
    if @myError <> 0
    Begin
        -- Return zero, since we did not create a protein collection
        Return 0
    End

    -- Make sure the Source and Description do not have text surrounded by < and >, since web browsers will treat that as an HTML tag
    Set @collectionSource = REPLACE(REPLACE(Coalesce(@collectionSource, ''), '<', '('), '>', ')')
    Set @description =      REPLACE(REPLACE(Coalesce(@description,      ''), '<', '('), '>', ')')

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------
    
    declare @collectionID Int = 0
    
    execute @collectionID = GetProteinCollectionID @collectionName
    
    if @collectionID > 0 and @mode = 'add'
    begin
        -- Collection already exists; change @mode to 'update'
        set @mode = 'update'
    end
    
    if @collectionID = 0 and @mode = 'update'
    begin
        -- Collection not found; change @mode to 'add'
        set @mode = 'add'
    end
    
    -- Uncomment to debug
    --
    -- set @message = 'mode ' + @mode + ', collection '+ @collectionName
    -- exec PostLogEntry 'Debug', @message, 'AddUpdateProteinCollection'
    -- set @message=''
    
    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    declare @transName varchar(32) = 'AddProteinCollectionEntry'
    begin transaction @transName
    
    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    if @mode = 'add'
    begin
    
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
            @collection_type,
            @collection_state,
            @primary_annotation_type_id,
            @numProteins, 
            @numResidues,
            GETDATE(),
            GETDATE(),
            SYSTEM_USER
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @message = 'Insert operation failed: "' + @collectionName + '"'
            RAISERROR (@message, 10, 1)
            -- Return zero, since we did not create a protein collection
            Return 0
        end
    
--            INSERT INTO T_Annotation_Groups (
--            Protein_Collection_ID,
--            Annotation_Group,
--            Annotation_Type_ID
--            ) VALUES (
--            @collectionID,
--            0,
--            @primary_annotation_type_id
--            )
        
    end
    
    if @mode = 'update'
    begin
        
        UPDATE T_Protein_Collections
        SET
            Description = @description,
            Source = Case When @collectionSource = '' and IsNull(Source, '') <> '' Then Source Else @collectionSource End,
            Collection_State_ID = @collection_state,
            Collection_Type_ID = @collection_type,
            NumProteins = @numProteins,
            NumResidues = @numResidues,
            DateModified = GETDATE()        
        WHERE Collection_Name = @collectionName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @message = 'Update operation failed: "' + @collectionName + '"'
            RAISERROR (@message, 10, 1)
            -- Return zero, since we did not create a protein collection
            Return 0
        end
    end
    
    commit transaction @transName

    -- Lookup the collection ID
    execute @collectionID = GetProteinCollectionID @collectionName
    
    if @mode = 'add'
    begin
        set @transName = 'AddProteinCollectionEntry'
        begin transaction @transName
    
        INSERT INTO T_Annotation_Groups (
            Protein_Collection_ID,
            Annotation_Group,
            Annotation_Type_ID
        ) VALUES (
            @collectionID,
            0,
            @primary_annotation_type_id
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @message = 'Update operation failed: "' + @collectionName + '"'
            RAISERROR (@message, 10, 1)
            -- Return zero, since we did not create a protein collection
            Return 0
        end
        
        commit transaction @transName
    end
        
    return @collectionID

GO
GRANT EXECUTE ON [dbo].[AddUpdateProteinCollection] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
