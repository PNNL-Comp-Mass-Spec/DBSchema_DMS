/****** Object:  StoredProcedure [dbo].[duplicate_manager_parameter] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[duplicate_manager_parameter]
/****************************************************
**
**  Desc:   Duplicates an existing parameter for all managers,
**          creating a new entry with a new TypeID value
**
**  Example usage:
**    exec duplicate_manager_parameter 157, 172, @ParamValueSearchText='msfileinfoscanner', @ParamValueReplaceText='AgilentToUimfConverter', @InfoOnly=1
**
**    exec duplicate_manager_parameter 179, 182, @ParamValueSearchText='PbfGen', @ParamValueReplaceText='ProMex', @InfoOnly=1
**
**  Auth:   mem
**  Date:   08/26/2013 mem - Initial release
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @sourceParamTypeID int,
    @newParamTypeID int,
    @paramValueOverride varchar(255) = null,        -- Optional: New parameter value; ignored if @ParamValueSearchText is defined
    @commentOverride varchar(255) = null,
    @paramValueSearchText varchar(255) = null,      -- Optional: text to search for in the source parameter value
    @paramValueReplaceText varchar(255) = null,     -- Optional: replacement text (ignored if @ParamValueReplaceText is null)
    @infoOnly tinyint = 1
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    set @InfoOnly = IsNull(@InfoOnly, 1)

    If @SourceParamTypeID Is Null
    Begin
        Print '@SourceParamTypeID cannot be null; unable to continue'
        return 52000
    End

    If @NewParamTypeID Is Null
    Begin
        Print '@NewParamTypeID cannot be null; unable to continue'
        return 52001
    End

    If Not @ParamValueSearchText Is Null AND @ParamValueReplaceText Is Null
    Begin
        Print '@ParamValueReplaceText cannot be null when @ParamValueSearchText is defined; unable to continue'
        return 52002
    End

    ---------------------------------------------------
    -- Make sure the soure parameter exists
    ---------------------------------------------------

    If Not Exists (Select * From T_ParamValue Where TypeID = @SourceParamTypeID)
    Begin
        Print '@SourceParamTypeID ' + Convert(varchar(12), @SourceParamTypeID) + ' not found in T_ParamValue; unable to continue'
        return 52003
    End

    If Exists (Select * From T_ParamValue Where TypeID = @NewParamTypeID)
    Begin
        Print '@NewParamTypeID ' + Convert(varchar(12), @NewParamTypeID) + ' already exists in T_ParamValue; unable to continue'
        return 52004
    End

    If Not Exists (Select * From T_ParamType Where ParamID = @NewParamTypeID)
    Begin
        Print '@NewParamTypeID ' + Convert(varchar(12), @NewParamTypeID) + ' not found in T_ParamType; unable to continue'
        return 52005
    End


    If Not @ParamValueSearchText Is Null
    Begin
        If @InfoOnly <> 0
            SELECT @NewParamTypeID AS TypeID,
                REPLACE([Value], @ParamValueSearchText, @ParamValueReplaceText) AS [Value],
                MgrID,
                IsNull(@CommentOverride, '') AS [Comment]
            FROM T_ParamValue
            WHERE (TypeID = @SourceParamTypeID)
        Else
            INSERT INTO T_ParamValue( TypeID,
                                    [Value],
                                    MgrID,
                                    [Comment] )
            SELECT @NewParamTypeID AS TypeID,
                REPLACE([Value], @ParamValueSearchText, @ParamValueReplaceText) AS [Value],
                MgrID,
                IsNull(@CommentOverride, '') AS [Comment]
            FROM T_ParamValue
            WHERE (TypeID = @SourceParamTypeID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End
    Else
    Begin
        If @InfoOnly <> 0
            SELECT @NewParamTypeID AS TypeID,
                   IsNull(@ParamValueOverride, [Value]) AS [Value],
                   MgrID,
                   IsNull(@CommentOverride, '') AS [Comment]
            FROM T_ParamValue
            WHERE (TypeID = @SourceParamTypeID)
        Else
            INSERT INTO T_ParamValue( TypeID,
                                      [Value],
                                      MgrID,
                                      [Comment] )
            SELECT @NewParamTypeID AS TypeID,
                   IsNull(@ParamValueOverride, [Value]) AS [Value],
                   MgrID,
                   IsNull(@CommentOverride, '') AS [Comment]
            FROM T_ParamValue
            WHERE (TypeID = @SourceParamTypeID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    return 0

GO
