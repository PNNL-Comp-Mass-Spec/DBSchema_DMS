/****** Object:  StoredProcedure [dbo].[add_update_protein_collection_member] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_protein_collection_member]
/****************************************************
**
**  Desc: Adds a new protein collection member
**
**  Return values: 0: success, otherwise, error code
**
**
**
**  Auth:   kja
**  Date:   10/06/2004
**          11/23/2005 kja - Added parameters
**          12/11/2012 mem - Removed transaction
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @reference_ID int,
    @protein_ID int,
    @protein_collection_ID int,
    @sorting_index int,
    @mode varchar(10),
    @message varchar(256) output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    declare @msg varchar(256)
    declare @member_ID int

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

--  declare @ID_Check int
--  set @ID_Check = 0
--
--  SELECT @ID_Check = Protein_ID FROM T_Protein_Collection_Members
--  WHERE Protein_Collection_ID = @protein_collection_ID
--
--  if @ID_Check > 0
--  begin
--      return 1  -- Entry already exists
--  end

    if @mode = 'add'
    begin
        ---------------------------------------------------
        -- action for add mode
        ---------------------------------------------------
        --
        INSERT INTO T_Protein_Collection_Members (
            Original_Reference_ID,
            Protein_ID,
            Protein_Collection_ID,
            Sorting_Index
        ) VALUES (
            @reference_ID,
            @protein_ID,
            @protein_collection_ID,
            @sorting_index
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount, @member_ID = SCOPE_IDENTITY()
        --
        if @myError <> 0
        begin
            set @msg = 'Insert operation failed for Protein_ID: "' + Convert(varchar(12), @protein_ID) + '"'
            RAISERROR (@msg, 10, 1)
            return 51007
        end
    end

    if @mode = 'update'
    begin
        ---------------------------------------------------
        -- action for update mode
        ---------------------------------------------------
        --
        UPDATE T_Protein_Collection_Members
        SET Sorting_Index = @sorting_index
        WHERE (Protein_ID = @protein_ID and Original_Reference_ID = @reference_ID and Protein_Collection_ID = @protein_collection_ID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
            --
        if @myError <> 0
        begin
            set @msg = 'Update operation failed for Protein_ID: "' + Convert(varchar(12), @protein_ID) + '"'
            RAISERROR (@msg, 10, 1)
            return 51008
        end
    end

    return @member_ID

GO
GRANT EXECUTE ON [dbo].[add_update_protein_collection_member] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
