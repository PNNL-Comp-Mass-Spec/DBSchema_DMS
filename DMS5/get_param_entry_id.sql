/****** Object:  StoredProcedure [dbo].[GetParamEntryID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetParamEntryID]
/****************************************************
**
**  Desc: Gets ParamEntryID for given set of param entry specs
**
**  Return values: 0: failure, otherwise, ParamFileID
**
**  Auth:   kja
**  Date:   08/22/2004
**          08/03/2017 mem - Add Set NoCount On
**
*****************************************************/
(
    @ParamFileID int,
    @EntryType varchar(32),
    @EntrySpecifier varchar(32),
    @EntrySeqOrder int
)
AS
    Set NoCount On

    Declare @ParamEntryID int = 0

    SELECT @ParamEntryID = Param_Entry_ID
    FROM T_Param_Entries
    WHERE Param_File_ID = @ParamFileID AND
          Entry_Type = @EntryType AND
          Entry_Specifier = @EntrySpecifier AND
          Entry_Sequence_Order = @EntrySeqOrder


    return(@ParamEntryID)

GO
GRANT VIEW DEFINITION ON [dbo].[GetParamEntryID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetParamEntryID] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetParamEntryID] TO [Limited_Table_Write] AS [dbo]
GO
