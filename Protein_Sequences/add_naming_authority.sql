/****** Object:  StoredProcedure [dbo].[add_naming_authority] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_naming_authority]
/****************************************************
**
**  Desc: Adds or changes an annotation naming authority
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**
**
**  Auth:   kja
**  Date:   12/14/2005
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @name varchar(64),
    @description varchar(128),
    @web_address varchar(128),
    @message varchar(256) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    declare @msg varchar(256)
    declare @member_ID int

    declare @auth_id int
    set @auth_id = 0

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    execute @auth_id = get_naming_authority_id @name

    if @auth_id > 0
    begin
        return -@auth_id
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
    INSERT INTO T_Naming_Authorities
               ([Name], Description, Web_Address)
    VALUES     (@name, @description, @web_address)


    SELECT @auth_id = @@Identity

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

    return @auth_ID

GO
GRANT EXECUTE ON [dbo].[add_naming_authority] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
