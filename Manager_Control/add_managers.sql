/****** Object:  StoredProcedure [dbo].[add_managers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_managers]
/****************************************************
**
**  Desc:
**  Adds multiple managers from a list of Manager names
**  based on manager type to the manager control database
**
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   jds
**  Date:   08/17/2007
**          05/14/2007 jds - spelled out the fields to insert for T_ParamValue(TypeID, [Value], MgrID)
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @managerTypeID int,
    @managerNameList varchar(2048)
)
AS
declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0
    --

    ---------------------------------------------------
    -- Insert managers in list into T_Mgrs table
    ---------------------------------------------------

    BEGIN TRANSACTION T1

    Insert into T_Mgrs(M_Name, M_TypeID, M_ParmValueChanged, M_ControlFromWebsite)
    select Item, @managerTypeID, 0, 1
    from make_table_from_list(@managerNameList)

    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        ROLLBACK TRANSACTION T1
        RAISERROR ('Error trying to insert Manager Names', 10, 1)
        return 51310
    end

    ---------------------------------------------------
    -- Insert parameters for Managers in list into T_ParamValue table
    ---------------------------------------------------
    Insert Into T_ParamValue(TypeID, [Value], MgrID)
    Select P.ParamTypeID, P.DefaultValue, nMgrs.M_ID
    From (
        Select MPM.ParamTypeID, MPM.DefaultValue
        From T_MgrType_ParamType_Map MPM
        Where MPM.MgrTypeID = @managerTypeID and DefaultValue is not null
         ) P,
        (
        select M_ID from T_Mgrs
        where M_Name in
            (
            SELECT * FROM make_table_from_list(@managerNameList)
            )
        ) nMgrs

    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        ROLLBACK TRANSACTION T1
        RAISERROR ('Error trying to insert parameters for Managers', 10, 1)
        return 51311
    end

    COMMIT TRANSACTION T1
    return @myError

GO
GRANT EXECUTE ON [dbo].[add_managers] TO [Mgr_Config_Admin] AS [dbo]
GO
