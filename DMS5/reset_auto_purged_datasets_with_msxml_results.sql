/****** Object:  StoredProcedure [dbo].[ResetAutoPurgedDatasetsWithMSXmlResults] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ResetAutoPurgedDatasetsWithMSXmlResults]
/****************************************************
**
**  Desc:   Looks for datasets with archive state 14 (Purged Instrument Data (plus auto-purge))
**          that have potentially unpurged MSXml jobs.  Changes the
**          dataset archive state back to 3=Complete to give the
**          space manager a chance to purge the .mzXML file
**
**          This procedure is no longer needed because we use _CacheInfo.txt placholder files
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   01/13/2014 mem - Initial version
**          02/23/2016 mem - Add set XACT_ABORT on
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**
*****************************************************/
(
    @InfoOnly tinyint = 0,                  -- 1 to preview the datasets that would be reset
    @ResetCount int = 0 output,             -- Number of datasets that were reset
    @message varchar(512)='' output
)
AS
    Set XACT_ABORT, nocount on

    declare @myError int
    declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    Set @InfoOnly = IsNull(@InfoOnly, 0)

    Set @message = ''
    Set @ResetCount = 0

    CREATE TABLE #Tmp_Datasets (
        Dataset_ID int NOT NULL
    )

    BEGIN TRY

        -- Find datasets to update

        INSERT INTO #Tmp_Datasets (Dataset_ID)
        SELECT DISTINCT DS.Dataset_ID
        FROM T_Dataset DS
             INNER JOIN T_Dataset_Archive DA
               ON DS.Dataset_ID = DA.AS_Dataset_ID
             INNER JOIN T_Analysis_Job J
               ON DS.Dataset_ID = J.AJ_datasetID
             INNER JOIN T_Analysis_Tool AnTool
               ON J.AJ_analysisToolID = AnTool.AJT_toolID
        WHERE (DA.AS_state_ID = 14) AND
              (AnTool.AJT_toolName LIKE 'MSXML%') AND
              DA.AS_state_Last_Affected < DateAdd(day, -180, GetDate()) AND
              (J.AJ_Purged = 0)

        If @infoOnly <> 0
        Begin
            ------------------------------------------------
            -- Preview the datasets that would be reset
            ------------------------------------------------
            --
            SELECT DS.Dataset_ID,
                   DS.Dataset_Num AS Dataset,
                   DA.AS_state_ID AS Archive_State_ID,
                   DASN.DASN_StateName AS Archive_State,
                   DA.AS_state_Last_Affected AS Archive_State_Last_Affected
            FROM T_Dataset DS
                 INNER JOIN #Tmp_Datasets U
                   ON DS.Dataset_ID = U.Dataset_ID
                 INNER JOIN T_Dataset_Archive DA
                   ON DS.Dataset_ID = DA.AS_Dataset_ID
                 INNER JOIN T_DatasetArchiveStateName DASN
                   ON DA.AS_state_ID = DASN.DASN_StateID
            ORDER BY DS.DS_Created Desc
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        End
        Else
        Begin
            ------------------------------------------------
            -- Change the dataset archive state back to 3
            ------------------------------------------------

            UPDATE T_Dataset_Archive
            SET AS_state_ID = 3
            FROM T_Dataset_Archive DA
                 INNER JOIN #Tmp_Datasets U
                   ON DA.AS_Dataset_ID = U.Dataset_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @ResetCount = @myRowCount

            If @ResetCount > 0
                Set @message = 'Reset dataset archive state from "Purged Instrument Data (plus auto-purge)" to "Complete" for ' + Convert(varchar(12), @myRowCount) + ' Datasets'
            Else
                Set @message = 'No candidate datasets were found to reset'

            If @ResetCount > 0
            Begin
                exec PostLogEntry 'Normal', @message, 'ResetAutoPurgedDatasetsWithMSXmlResults'
            End
        End


    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output
        Exec PostLogEntry 'Error', @message, 'ResetAutoPurgedDatasetsWithMSXmlResults'
    END CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ResetAutoPurgedDatasetsWithMSXmlResults] TO [DDL_Viewer] AS [dbo]
GO
