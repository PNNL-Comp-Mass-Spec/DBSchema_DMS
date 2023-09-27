/****** Object:  StoredProcedure [dbo].[get_package_dataset_job_tool_crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_package_dataset_job_tool_crosstab]
/****************************************************
**
**  Desc:
**      Generate a crosstab of data package datasets against job count per tool
**
**  Auth:   grk
**  Date:   05/26/2010 grk - Initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          10/26/2022 mem - Change column #id to lowercase
**          10/31/2022 mem - Use new column name id in the temp table
**          01/27/2023 mem - Change column names to lowercase
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          08/17/2023 mem - Use renamed column data_pkg_id in data package tables
**          09/26/2023 mem - Obtain dataset names and analysis tool names from T_Dataset and T_Analysis_Tool
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

    BEGIN TRY

        ---------------------------------------------------
        -- Create temp tables
        ---------------------------------------------------
        --
        CREATE TABLE #Tools (
            Tool varchar(128)
        )

        CREATE TABLE #Scratch (
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
        INSERT INTO #Datasets ( Dataset, id )
        SELECT DISTINCT DS.Dataset_Num,
                        @DataPackageID
        FROM T_Data_Package_Datasets TD
             INNER JOIN S_Dataset DS
               ON TD.Dataset_ID = DS.Dataset_ID
        WHERE TD.Data_Pkg_ID = @DataPackageID

        -- Update job counts
        UPDATE #Datasets
        SET Jobs = CountQ.Job_Count
        FROM #Datasets
             INNER JOIN ( SELECT DS.Dataset_Num AS Dataset,
                                 COUNT(*) AS Job_Count
                          FROM T_Data_Package_Analysis_Jobs DPJ
                               INNER JOIN S_Analysis_Job AJ
                                 ON AJ.AJ_jobID = DPJ.Job
                               INNER JOIN S_Dataset DS
                                 ON AJ.AJ_datasetID = DS.Dataset_ID
                          WHERE DPJ.Data_Pkg_ID = @DataPackageID
                          GROUP BY DS.Dataset_Num ) CountQ
               ON CountQ.Dataset = #Datasets.Dataset

        ---------------------------------------------------
        -- Get list of tools covered by package jobs
        ---------------------------------------------------
        --
        INSERT INTO #Tools ( Tool )
        SELECT DISTINCT T.AJT_toolName
        FROM T_Data_Package_Analysis_Jobs DPJ
             INNER JOIN S_Analysis_Job AJ
               ON AJ.AJ_jobID = DPJ.Job
             INNER JOIN S_Analysis_Tool T
               ON AJ.AJ_analysisToolID = T.AJT_toolID
        WHERE DPJ.Data_Pkg_ID = @DataPackageID


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

                INSERT INTO #Scratch ( Dataset, Total )
                SELECT DS.Dataset_Num,
                       COUNT(*) AS Total
                FROM T_Data_Package_Analysis_Jobs DPJ
                     INNER JOIN S_Analysis_Job AJ
                       ON AJ.AJ_jobID = DPJ.Job
                     INNER JOIN S_Dataset DS
                       ON AJ.AJ_datasetID = DS.Dataset_ID
                     INNER JOIN S_Analysis_Tool T
                       ON AJ.AJ_analysisToolID = T.AJT_toolID
                WHERE DPJ.Data_Pkg_ID = @DataPackageID AND
                      T.AJT_toolName = @colName
                GROUP BY DS.Dataset_Num

                SET @s = REPLACE('UPDATE #Datasets SET @col@ = TX.Total FROM #Datasets INNER JOIN #Scratch TX ON TX.Dataset = #Datasets.Dataset', '@col@', @colName)
                EXEC(@s)

            END --<b>
        END --<a>

        SELECT * FROM #Datasets

        ---------------------------------------------------
        -- Drop temp tables
        ---------------------------------------------------
        --
        DROP TABLE #Tools
        DROP TABLE #Scratch
        DROP TABLE #Datasets

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
