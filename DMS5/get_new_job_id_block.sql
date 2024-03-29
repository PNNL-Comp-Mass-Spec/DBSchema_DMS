/****** Object:  StoredProcedure [dbo].[get_new_job_id_block] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_new_job_id_block]
/****************************************************
**
**  Desc:
**    Gets a series of unique numbers for making multiple jobs
**
**    The calling procedure must create temporary table #TmpNewJobIDs with one column: ID
**      CREATE TABLE #TmpNewJobIDs (ID int)
**
**    This procedure will populate #TmpNewJobIDs with the new job numbers
**
**    Returns 0 if success, error number if failure
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   08/05/2009 - initial release (Ticket #744, http://prismtrac.pnl.gov/trac/ticket/744)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @jobCount int,          -- Number of jobs to make
    @note varchar(266)
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    declare @JobIDStart int
    declare @JobIDEnd int

    Declare @CurrentID int

    -- Clear the table
    DELETE FROM #TmpNewJobIDs

    If @JobCount <= 0
    Begin
        -- @JobCount was negative; nothing to do
        Set @myError = 52000
    End
    Else
    Begin

        -- Create a table variable that will hold a list of integers
        -- This variable will be used to insert a contiguous block of rows in T_Analysis_Job_ID
        declare @NumList table (ID int)

        -- Populate @NumList

        Set @CurrentID = 1
        While @CurrentID <= @JobCount
        Begin
            INSERT INTO @NumList (ID)
            VALUES (@CurrentID)

            Set @CurrentID = @CurrentID + 1
        End

        -- Now use @NumList to enter multiple rows into T_Analysis_Job_ID
        INSERT INTO T_Analysis_Job_ID ( Note )
        SELECT @note
        FROM @NumList
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError = 0
        begin
            -- Update #TmpNewJobIDs with the new job numbers added to T_Analysis_Job_ID
            -- Use SCOPE_IDENTITY() to determine the highest job number added by this procedure

            set @JobIDEnd = SCOPE_IDENTITY()
            Set @JobIDStart = @JobIDEnd - @myRowCount + 1

            INSERT INTO #TmpNewJobIDs ( ID )
            SELECT ID
            FROM T_Analysis_Job_ID
            WHERE ID BETWEEN @JobIDStart AND @JobIDEnd
            ORDER BY ID

        end
    End

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_new_job_id_block] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_new_job_id_block] TO [Limited_Table_Write] AS [dbo]
GO
