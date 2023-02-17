/****** Object:  StoredProcedure [dbo].[UpdatePipelineJobStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdatePipelineJobStats]
/****************************************************
**
**  Desc:   Update processing statistics in T_Pipeline_Job_Stats
**
**  Auth:   mem
**  Date:   05/29/2022 mem - Initial version
**
*****************************************************/
(
    @infoOnly tinyint = 0,
    @message varchar(512)='' output
)
As
    Set NoCount On

    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''

    ---------------------------------------------------
    -- Create a temp table to hold the statistics
    ---------------------------------------------------

    CREATE TABLE #Tmp_Pipeline_Job_Stats (
        Script     varchar(64) NOT NULL,
        Instrument_Group varchar(64) NOT NULL,
        [Year]     int NOT NULL,
        Jobs       int NOT NULL,
        PRIMARY KEY CLUSTERED ( Script, Instrument_Group, [Year] )
    )

    ---------------------------------------------------
    -- Summarize jobs by script, instrument group, and year
    ---------------------------------------------------

    INSERT INTO #Tmp_Pipeline_Job_Stats( Script, Instrument_Group, [Year], Jobs )
    SELECT JH.Script,
           IsNull(InstName.IN_Group, '') AS Instrument_Group,
           YEAR(JH.Start) AS [Year],
           COUNT(*) AS Jobs
    FROM T_Jobs_History JH
         LEFT OUTER JOIN S_DMS_T_Analysis_Job J
           ON JH.Job = J.AJ_JobID
         LEFT OUTER JOIN S_DMS_T_Dataset DS
           ON J.AJ_datasetID = DS.Dataset_ID
         LEFT OUTER JOIN S_DMS_T_Instrument_Name InstName
           ON DS.DS_instrument_name_ID = InstName.Instrument_ID
    WHERE NOT JH.Start IS NULL
    GROUP BY JH.Script, IsNull(InstName.IN_Group, ''), YEAR(JH.Start)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'No rows were added to #Tmp_Pipeline_Job_Stats; exiting'
        Goto Done
    End

    If @infoOnly > 0
    Begin
        SELECT Script,
               Instrument_Group,
               [Year],
               Jobs
        FROM #Tmp_Pipeline_Job_Stats
        ORDER BY Script, Instrument_Group, [Year]

        Goto Done
    End

    ---------------------------------------------------
    -- Update cached stats in T_Pipeline_Job_Stats
    --
    -- Since old jobs get deleted from T_Jobs_History,
    -- assure that the maximum value is used for each row
    ---------------------------------------------------

    MERGE T_Pipeline_Job_Stats AS t
    USING (SELECT Script, Instrument_Group, [Year], Jobs FROM #Tmp_Pipeline_Job_Stats) as s
    ON ( t.Instrument_Group = s.Instrument_Group AND t.Script = s.Script AND t.[Year] = s.[Year])
    WHEN MATCHED AND (
        t.Jobs < s.Jobs
        )
    THEN UPDATE SET
        Jobs = s.Jobs
    WHEN NOT MATCHED BY TARGET THEN
        INSERT(Script, Instrument_Group, [Year], Jobs)
        VALUES(s.Script, s.Instrument_Group, s.[Year], s.Jobs);
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Set @message = 'Updated ' + Cast(@myRowCount As Varchar(12)) + ' rows in T_Pipeline_Job_Stats'

Done:
    If @myError <> 0
    Begin
        If @message = ''
            Set @message = 'Error in UpdatePipelineJobStats'

        Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)

        If @InfoOnly = 0
            Exec PostLogEntry 'Error', @message, 'UpdatePipelineJobStats'
    End

    If Len(@message) > 0
        Print @message

    Return @myError


GO
