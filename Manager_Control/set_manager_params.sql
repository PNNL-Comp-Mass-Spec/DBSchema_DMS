/****** Object:  StoredProcedure [dbo].[set_manager_params] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[set_manager_params]
/****************************************************
**
**  Desc:
**    Sets the values of parameters given in XML format
**    for the given manager
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   04/27/2007
**          05/02/2007 grk - added translation table
**          05/02/2007 grk - fixed too-narrow variables in OPENXML
**          05/02/2007 grk - fixed sloppy final update statement
**          05/02/2007 dac - added translation for bionet password
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @managerName varchar(128),
    @xmlDoc nvarchar(3500),
    @mode varchar(24) = 'InfoOnly',
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''


    ---------------------------------------------------
    -- Resolve manager name to manager ID
    ---------------------------------------------------
    declare @mgrID int
    set @mgrID = 0
    --
    SELECT @mgrID = M_ID
    FROM T_Mgrs
    WHERE (M_Name = @managerName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error trying to resolve manager name to ID'
      Goto Done
    end
    --
    if @mgrID = 0
    begin
      set @message = 'Could not find manager ID'
        set @myError = 51000
      Goto Done
    end

    ---------------------------------------------------
    --  Create temporary table to hold list of parameters
    ---------------------------------------------------

    CREATE TABLE #TDS (
        paramID int NULL,
        paramName varchar(128),
        paramValue varchar(255)
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Failed to create temporary parameter table'
        Goto Done
    end
    ---------------------------------------------------
    -- Parse the XML input
    ---------------------------------------------------
    DECLARE @hDoc int
    EXEC sp_xml_preparedocument @hDoc OUTPUT, @xmlDoc

    ---------------------------------------------------
    -- Populate table from XML parameter description
    -- Using OPENXML in a SELECT statement to read data from XML file
    ---------------------------------------------------

    INSERT INTO #TDS
    (paramName, paramValue)
    SELECT * FROM OPENXML(@hDoc, N'//section/item')  with ([key] varchar(128), value varchar(128))
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error populating temporary parameter table'
        Goto Done
    end

    -- Remove the internal representation of the XML document.
    EXEC sp_xml_removedocument @hDoc


    ---------------------------------------------------
    -- FUTURE: translate parameter names that have changed
    ---------------------------------------------------

    UPDATE #TDS SET paramName = 'maxrepetitions' WHERE paramName = 'maxjobcount'
    UPDATE #TDS SET paramName = 'bionetpwd' WHERE paramName = 'bionetmisc'
--  UPDATE #TDS SET paramName = '' WHERE paramName = ''

    ---------------------------------------------------
    -- Get parameter IDs for parameters
    ---------------------------------------------------

    UPDATE T
    SET T.paramID = T_ParamType.ParamID
    FROM #TDS T INNER JOIN
    T_ParamType ON T_ParamType.ParamName = T.paramName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error getting parameter IDs'
        Goto Done
    end

    ---------------------------------------------------
    -- Trap "information only mode" here
    ---------------------------------------------------
    if @mode = 'InfoOnly'
    begin
        select * from #TDS
        Goto Done
    end

    ---------------------------------------------------
    -- FUTURE: check for parameters that didn't get IDs
    ---------------------------------------------------
    -- for now, just remove them from table
    --
    DELETE FROM #TDS
    WHERE #TDS.paramID is NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Cleaning up parameter IDs'
        Goto Done
    end

    ---------------------------------------------------
    -- Insert paramters that aren't already in table
    ---------------------------------------------------

    INSERT INTO T_ParamValue
        (MgrID, TypeID, Value)
    SELECT @mgrID, #TDS.paramID, #TDS.paramValue
    FROM #TDS
    WHERE #TDS.paramID NOT IN (SELECT TypeID FROM T_ParamValue WHERE MgrID = @mgrID)

    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error inserting new parameteres'
        Goto Done
    end


    ---------------------------------------------------
    -- Update parameters
    ---------------------------------------------------

    UPDATE M
    SET M.Value = T.paramValue
    FROM T_ParamValue M INNER JOIN
    #TDS T ON T.paramID = M.TypeID AND M.MgrID = @mgrID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error updating parameteres'
        Goto Done
    end
    
Done:
    return @myError

GO
GRANT EXECUTE ON [dbo].[set_manager_params] TO [Mgr_Config_Admin] AS [dbo]
GO
