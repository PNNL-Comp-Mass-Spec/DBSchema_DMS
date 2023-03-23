/****** Object:  StoredProcedure [dbo].[add_annotation_type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_annotation_type]
/****************************************************
**
**  Desc: Adds or changes an annotation naming authority
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   kja
**  Date:   01/11/2006
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
*****************************************************/
(
    @name varchar(64),
    @description varchar(128),
    @example varchar(128),
    @authID int,
    @message varchar(256) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    declare @msg varchar(256)
    declare @memberID int

    declare @annTypeId int
    set @annTypeId = 0

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    execute @annTypeId = get_annotation_type_id @name, @authID

    if @annTypeId > 0
    begin
        return -@annTypeId
    end

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    declare @transName varchar(32)
    set @transName = 'add_naming_authority'
    begin transaction @transName


    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    INSERT INTO T_Annotation_Types
               (TypeName, Description, Example, Authority_ID)
    VALUES     (@name, @description, @example, @authID)


    SELECT @annTypeId = @@Identity

    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @msg = 'Insert operation failed: "' + @name + '"'
        RAISERROR (@msg, 10, 1)
        return 51007
    end

    commit transaction @transName

    return @annTypeId

GO
GRANT EXECUTE ON [dbo].[add_annotation_type] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
