/****** Object:  UserDefinedFunction [dbo].[get_param_entry_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_param_entry_id]
/****************************************************
**
**  Desc: Gets ParamEntryID for given set of param entry specs
**
**  Return values: 0: failure, otherwise, ParamFileID
**
**  Auth:   kja
**  Date:   08/22/2004
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @paramFileID int,
    @entryType varchar(32),
    @entrySpecifier varchar(32),
    @entrySeqOrder int
)
RETURNS int
AS
BEGIN
    Declare @ParamEntryID int = 0

    SELECT @ParamEntryID = Param_Entry_ID
    FROM T_Param_Entries
    WHERE Param_File_ID = @ParamFileID AND
          Entry_Type = @EntryType AND
          Entry_Specifier = @EntrySpecifier AND
          Entry_Sequence_Order = @EntrySeqOrder


    return(@ParamEntryID)
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_param_entry_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_param_entry_id] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_param_entry_id] TO [Limited_Table_Write] AS [dbo]
GO
