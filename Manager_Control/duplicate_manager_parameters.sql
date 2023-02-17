/****** Object:  StoredProcedure [dbo].[duplicate_manager_parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[duplicate_manager_parameters]
/****************************************************
**
**  Desc:   Duplicates the parameters for a given manager
**          to create new parameters for a new manager
**
**  Example usage:
**    exec duplicate_manager_parameter 157, 172
**
**  Auth:   mem
**  Date:   10/10/2014 mem - Initial release
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @sourceMgrID int,
    @targetMgrID int,
    @mergeSourceWithTarget tinyint = 0,         -- When 0, then the target manager cannot have any parameters; if 1, then will add missing parameters to the target manager
    @infoOnly tinyint = 0
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

    If @SourceMgrID Is Null
    Begin
        Print '@SourceMgrID cannot be null; unable to continue'
        return 52000
    End

    If @TargetMgrID Is Null
    Begin
        Print '@TargetMgrID cannot be null; unable to continue'
        return 52001
    End

    Set @MergeSourceWithTarget = IsNull(@MergeSourceWithTarget, 0)

    ---------------------------------------------------
    -- Make sure the source and target managers exist
    ---------------------------------------------------

    If Not Exists (Select * From T_Mgrs Where M_ID = @SourceMgrID)
    Begin
        Print '@SourceMgrID ' + Convert(varchar(12), @SourceMgrID) + ' not found in T_Mgrs; unable to continue'
        return 52003
    End

    If Not Exists (Select * From T_Mgrs Where M_ID = @TargetMgrID)
    Begin
        Print '@TargetMgrID ' + Convert(varchar(12), @TargetMgrID) + ' not found in T_Mgrs; unable to continue'
        return 52004
    End

    If @MergeSourceWithTarget = 0
    Begin
        -- Make sure the target manager does not have any parameters
        --
        If Exists (SELECT * FROM T_ParamValue WHERE MgrID = @TargetMgrID)
        Begin
            Print '@TargetMgrID ' + Convert(varchar(12), @TargetMgrID) + ' has existing parameters in T_ParamValue; aborting since @MergeSourceWithTarget = 0'
            return 52005
        End
    End

    If @InfoOnly <> 0
    Begin
            SELECT Source.TypeID,
                   Source.Value,
                   @TargetMgrID AS MgrID,
                   Source.Comment
            FROM T_ParamValue AS Source
                 LEFT OUTER JOIN ( SELECT TypeID
                                   FROM T_ParamValue
                                   WHERE MgrID = @TargetMgrID ) AS ExistingParams
                   ON Source.TypeID = ExistingParams.TypeID
            WHERE MgrID = @SourceMgrID AND
                  ExistingParams.TypeID IS NULL

    End
    Else
    Begin
        INSERT INTO T_ParamValue (TypeID, Value, MgrID, Comment)
        SELECT Source.TypeID,
               Source.Value,
               @TargetMgrID AS MgrID,
               Source.Comment
        FROM T_ParamValue AS Source
             LEFT OUTER JOIN ( SELECT TypeID
                               FROM T_ParamValue
                               WHERE MgrID = @TargetMgrID ) AS ExistingParams
               ON Source.TypeID = ExistingParams.TypeID
        WHERE MgrID = @SourceMgrID AND
              ExistingParams.TypeID IS NULL
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    return 0

GO
