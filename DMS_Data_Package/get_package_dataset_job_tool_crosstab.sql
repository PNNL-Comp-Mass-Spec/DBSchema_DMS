/****** Object:  StoredProcedure [dbo].[get_package_dataset_job_tool_crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_package_dataset_job_tool_crosstab]
/****************************************************
**
**  Desc:
**  Crosstab of data package datasets against job count per tool
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   05/26/2010 grk - Initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          10/26/2022 mem - Change column #id to lowercase
**          10/31/2022 mem - Use new column name id in the temp table
**          01/27/2023 mem - Change column names to lowercase
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @dataPackageID int,
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    ---------------------------------------------------
    ---------------------------------------------------
    BEGIN TRY

        ---------------------------------------------------
        -- Create temp tables
        ---------------------------------------------------
        --
        CREATE TABLE #Tools (
            Tool varchar(128)
        )

        CREATE TABLE #Scratch  (
            Dataset varchar(128),
            Total int
        )

        CREATE TABLE #Datasets (
            dataset varchar(128),
            jobs int NULL,
            id int
        )

        ---------------------------------------------------
        -- Get list of package datasets
        ---------------------------------------------------
        --
        INSERT INTO #Datasets( Dataset,
                               id )
        SELECT DISTINCT Dataset,
                        @DataPackageID
        FROM T_Data_Package_Datasets
        WHERE Data_Package_ID = @DataPackageID

        -- Update job counts
        UPDATE #Datasets
        SET Jobs = TX.Total
        FROM #Datasets
             INNER JOIN ( SELECT Dataset,
                                 COUNT(*) AS Total
                          FROM T_Data_Package_Analysis_Jobs
                          WHERE Data_Package_ID = @DataPackageID
                          GROUP BY Dataset ) TX
               ON TX.Dataset = #Datasets.Dataset

        ---------------------------------------------------
        -- get list of tools covered by package jobs
        ---------------------------------------------------
        --
        INSERT INTO #Tools ( Tool )
        SELECT DISTINCT Tool
        FROM T_Data_Package_Analysis_Jobs
        WHERE Data_Package_ID = @DataPackageID


        ---------------------------------------------------
        -- Add columns to temp dataset table for each tool
        -- and update it with package job count
        ---------------------------------------------------
        Declare @colName varchar(128) = 0
        Declare @done tinyint = 0
        Declare @s nvarchar(1000)

        WHILE @done = 0
        BEGIN --<a>
        SET @colName = ''
            SELECT TOP 1 @colName = Tool
            FROM #Tools

            IF @colName = ''
            Begin
                SET @done = 1
            End
            ELSE
            BEGIN --<b>
                DELETE FROM #Tools WHERE Tool = @colName

                SET @s = REPLACE('ALTER TABLE #Datasets ADD @col@ int NULL', '@col@', @colName)
                EXEC(@s)

                DELETE FROM #Scratch
                --
                INSERT INTO #Scratch( Dataset,
                                      Total )
                SELECT Dataset,
                       COUNT(*) AS Total
                FROM T_Data_Package_Analysis_Jobs
                WHERE Data_Package_ID = @DataPackageID AND
                      Tool = @colName
                GROUP BY Dataset

                SET @s = REPLACE('UPDATE #Datasets SET @col@ = TX.Total FROM #Datasets INNER JOIN #Scratch TX ON TX.Dataset = #Datasets.Dataset', '@col@', @colName)
                EXEC(@s)

            END --<b>
        END --<a>

        SELECT * FROM #Datasets

        ---------------------------------------------------
        --
        ---------------------------------------------------
        --
        DROP TABLE #Tools
        DROP TABLE #Scratch
        DROP TABLE #Datasets

    ---------------------------------------------------
    ---------------------------------------------------
    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        Declare @msgForLog varchar(512) = ERROR_MESSAGE()
        Exec post_log_entry 'Error', @msgForLog, 'get_package_dataset_job_tool_crosstab'

    END CATCH

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_package_dataset_job_tool_crosstab] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_package_dataset_job_tool_crosstab] TO [DMS_SP_User] AS [dbo]
GO
