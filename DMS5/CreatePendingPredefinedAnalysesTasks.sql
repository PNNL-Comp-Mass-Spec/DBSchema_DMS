/****** Object:  StoredProcedure [dbo].[CreatePendingPredefinedAnalysesTasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreatePendingPredefinedAnalysesTasks]
/****************************************************
** 
**  Desc:
**      Creates job for new entries in T_Predefined_Analysis_Scheduling_Queue
**
**      Should be called periodically by a SQL Server Agent job 
**
**  Return values: 0: success, otherwise, error code
** 
**  Auth:   grk
**  Date:   08/26/2010 grk - initial release
**          08/26/2010 mem - Added @MaxDatasetsToProcess and @InfoOnly
**                         - Now passing @PreventDuplicateJobs to CreatePredefinedAnalysesJobs
**          03/27/2013 mem - Now obtaining Dataset name from T_Dataset
**          07/21/2016 mem - Fix logic error examining @myError
**          05/30/2018 mem - Do not create predefined jobs for inactive datasets
**    
*****************************************************/
(
    @MaxDatasetsToProcess int = 0,            -- Set to a positive number to limit the number of affected datasets
    @InfoOnly tinyint = 0
)
AS
    Set nocount on
    
    Declare @myError int
    Declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0

    Declare @message varchar(max) = ''

    Declare @datasetNum varchar(128)
    Declare @datasetID int
    Declare @datasetStateId int
    Declare @callingUser varchar(128)
    Declare @AnalysisToolNameFilter varchar(128)
    Declare @ExcludeDatasetsNotReleased tinyint
    Declare @PreventDuplicateJobs tinyint

    Declare @done tinyint
    Declare @currentItemID int
    Declare @DatasetsProcessed int
    Declare @JobsCreated int = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
     
    Set @MaxDatasetsToProcess = IsNull(@MaxDatasetsToProcess, 0)
    Set @InfoOnly = IsNull(@InfoOnly, 0)
    
    ---------------------------------------------------
    -- Process "New" entries in T_Predefined_Analysis_Scheduling_Queue
    ---------------------------------------------------
     
    Set @done = 0
    Set @currentItemID = 0
    Set @DatasetsProcessed = 0
     
    WHILE @done = 0
    Begin
        SET @datasetNum = ''
        Set @datasetStateId = 0

        SELECT TOP 1 @currentItemID = SQ.Item,
                     @datasetNum = D.Dataset_Num,
                     @datasetStateId = D.DS_state_ID,
                     @callingUser = SQ.CallingUser,
                     @AnalysisToolNameFilter = SQ.AnalysisToolNameFilter,
                     @ExcludeDatasetsNotReleased = SQ.ExcludeDatasetsNotReleased,
                     @PreventDuplicateJobs = SQ.PreventDuplicateJobs
        FROM T_Predefined_Analysis_Scheduling_Queue SQ
             INNER JOIN T_Dataset D
               ON SQ.Dataset_ID = D.Dataset_ID
        WHERE SQ.State = 'New' AND
              SQ.Item > @currentItemID
        ORDER BY SQ.Item ASC
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    
        If @myRowCount = 0
        Begin
            SET @done = 1
        End
        ELSE 
        Begin
            If @InfoOnly <> 0
            Begin
                PRINT 'Process Item ' + Convert(varchar(12), @currentItemID) + ': ' + @datasetNum
            End

            If IsNull(@datasetNum, '') = ''
            Begin
                -- Dataset not defined; skip this entry
                Set @myError = 50
                Set @message = 'Invalid entry: dataset name is blank'
            End
            Else If @datasetStateId = 4
            Begin
                -- Dataset state is Inactive
                Set @myError = 60
                Set @message = 'Inactive dataset: will not create predefined jobs'
            End
            Else
            Begin
                    
                EXEC @myError = dbo.CreatePredefinedAnalysesJobs 
                                                @datasetNum,
                                                @callingUser,
                                                @AnalysisToolNameFilter,
                                                @ExcludeDatasetsNotReleased,
                                                @PreventDuplicateJobs,
                                                @InfoOnly,
                                                @message output,
                                                @JobsCreated output

            End
        
            If @InfoOnly = 0
                UPDATE dbo.T_Predefined_Analysis_Scheduling_Queue
                SET Message = @message,
                    Result_Code = @myError,
                    State = CASE
                                WHEN @myError = 60 THEN 'Skipped'
                                WHEN @myError > 0 THEN 'Error'
                                ELSE 'Complete'
                            END,
                    Jobs_Created = ISNULL(@JobsCreated, 0),
                    Last_Affected = GetDate()
                WHERE Item = @currentItemID
            
            Set @DatasetsProcessed = @DatasetsProcessed + 1
        End 
        
        If @MaxDatasetsToProcess > 0 And @DatasetsProcessed >= @MaxDatasetsToProcess
        Begin
            Set @done = 1
        End
    End 
    
    If @InfoOnly <> 0
    Begin
        If @DatasetsProcessed = 0
            Set @message = 'No candidates were found in T_Predefined_Analysis_Scheduling_Queue'
        Else
        Begin
            Set @message = 'Processed ' + Convert(varchar(12), @DatasetsProcessed) + ' dataset'
            If @DatasetsProcessed <> 1
                Set @message = @message + 's'
        End
        
        Print @message
    End

    RETURN 0


GO
GRANT VIEW DEFINITION ON [dbo].[CreatePendingPredefinedAnalysesTasks] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CreatePendingPredefinedAnalysesTasks] TO [Limited_Table_Write] AS [dbo]
GO
