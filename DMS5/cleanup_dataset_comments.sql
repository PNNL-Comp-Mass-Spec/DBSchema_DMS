/****** Object:  StoredProcedure [dbo].[cleanup_dataset_comments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[cleanup_dataset_comments]
/****************************************************
**
**  Desc:   Remove error messages from dataset comments, provided the dataset state is Complete or Inactive
**
**  Auth:   mem
**  Date:   12/16/2017 mem - Initial version
**          01/02/2018 mem - Check for "Authentication failure" and "Error: NeedToAbortProcessing"
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetIDs varchar(1024),
    @message varchar(512) = '' output,
    @InfoOnly tinyint = 1
)
AS
    set nocount on

    Declare @myError int
    Declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0

    ----------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------

    Set @datasetIDs = IsNull(@datasetIDs, '')

    If @datasetIDs = ''
    Begin
        set @message = 'One or more dataset IDs is required'
        print @message
        Return 50000
    End

    Set @InfoOnly = IsNull(@InfoOnly, 1)
    ----------------------------------------------------
    -- Create some Temporary TAbles
    ----------------------------------------------------

    CREATE TABLE #TmpDatasetsToUpdate (
        DatasetID int,
        InvalidID tinyint,
        StateID int,
        ExistingComment varchar(512) null,
        NewComment varchar(512) null,
        UpdateRequired tinyint null
    );
    CREATE CLUSTERED INDEX #IX_TmpDatasetsToUpdate_DatasetID ON #TmpDatasetsToUpdate (DatasetID)

    CREATE TABLE #TmpMessagesToRemove (
        MessageID int identity(1,1),
        MessageText varchar(128)
    );

    -- Example errors to remove:
    --   Error while copying \\15TFTICR64\data\
    --   Error running OpenChrom
    --   Authentication failure: The user name or password is incorrect.
    --   Error: NeedToAbortProcessing

    INSERT INTO #TmpMessagesToRemove (MessageText)
    VALUES ('Error while copying \\'),
           ('Error running OpenChrom'),
           ('Authentication failure'),
           ('Error: NeedToAbortProcessing')

    ----------------------------------------------------
    -- Find datasets to process
    ----------------------------------------------------
    --

    INSERT #TmpDatasetsToUpdate (DatasetID, InvalidID, StateID, ExistingComment, NewComment)
    SELECT Src.Value,
           CASE WHEN DS.Dataset_ID IS NULL THEN 1 ELSE 0 END AS InvalidID,
           DS_State_ID,
           ExistingComment = DS.DS_Comment,
           NewComment = DS.DS_Comment
    FROM dbo.parse_delimited_integer_list ( @datasetIDs, ',' ) Src
         LEFT OUTER JOIN T_Dataset DS
           ON Src.Value = DS.Dataset_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If Not Exists (Select * From #TmpDatasetsToUpdate)
    Begin
        set @message = 'No valid integers were found: ' + @datasetIDs
        Return 50001
    End

    If Exists (Select * From #TmpDatasetsToUpdate WHERE InvalidID > 0)
    Begin
        Declare @unknownIDs varchar(1024) = null
        SELECT @unknownIDs = Coalesce(@unknownIDs + ', ' + Cast(DatasetID AS varchar(9)),
                                      Cast(DatasetID AS varchar(9)))
        FROM #TmpDatasetsToUpdate
        WHERE InvalidID > 0

        Set @message = 'Ignoring unknown DatasetIDs: ' + @unknownIDs
        print @message
        Set @message = ''
    End

    If Exists (Select * From #TmpDatasetsToUpdate WHERE InvalidID = 0 AND NOT StateID IN (3,4) )
    Begin
        Declare @IDsWrongState varchar(1024) = null
        SELECT @IDsWrongState = Coalesce(@IDsWrongState + ', ' + Cast(DatasetID AS varchar(9)),
                                        Cast(DatasetID AS varchar(9)))
        FROM #TmpDatasetsToUpdate
        WHERE InvalidID = 0 AND NOT StateID IN (3,4)

        Set @message = 'Ignoring Datasets not in state 3 or 4 (complete or inactive): ' + @IDsWrongState
        print @message
        Set @message = ''
    End

    Declare @datasetID int = 0
    Declare @comment varchar(512)

    Declare @continue tinyint = 1
    Declare @matchIndex int

    Declare @messageID int = 0
    Declare @messageText varchar(128)
    Declare @messagesAvailable tinyint = 1

    While @continue > 0
    Begin -- <a>

        SELECT TOP 1 @datasetID = DatasetID, @comment = NewComment
        FROM #TmpDatasetsToUpdate
        WHERE DatasetID > @datasetID AND
              InvalidID = 0 AND
              StateID IN (3, 4)
        ORDER BY DatasetID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
            Set @continue = 0
        Else
        Begin -- <b>

            Set @messagesAvailable = 1
            Set @messageID = 0

            While @messagesAvailable > 0
            Begin -- <c>
                SELECT TOP 1 @messageID = MessageID, @messageText = MessageText
                FROM #TmpMessagesToRemove
                WHERE MessageID > @messageID
                ORDER BY MessageID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                    Set @messagesAvailable = 0
                Else
                Begin -- <d>

                    Set @matchIndex = CharIndex('; ' + @messageText, @comment)

                    If @matchIndex = 0
                    Begin
                        Set @matchIndex = CharIndex(@messageText, @comment)
                    End

                    If @matchIndex = 1
                    Begin
                        Set @comment = ''
                    End

                    If @matchIndex > 1
                    Begin
                        -- Match found at the end; remove the error message but keep the initial part of the comment
                        Set @comment = RTrim(Substring(@comment, 1, @matchIndex - 1))
                    End

                    UPDATE #TmpDatasetsToUpdate
                    SET NewComment = @comment
                    WHERE DatasetID = @datasetID

                End -- </d>
            End -- </c>
        End -- </b>
    End -- </a>

    UPDATE #TmpDatasetsToUpdate
    SET UpdateRequired = CASE
                             WHEN IsNull(ExistingComment, '') <> IsNull(NewComment, '') THEN 1
                             ELSE 0
                         END

    If @InfoOnly <> 0
    Begin
        SELECT *
        FROM #TmpDatasetsToUpdate
        ORDER BY DatasetID

    End
    Else
    Begin
        UPDATE T_Dataset
        SET DS_Comment = NewComment
        FROM T_Dataset Target
             INNER JOIN #TmpDatasetsToUpdate Src
               ON Target.Dataset_ID = Src.DatasetID
        WHERE Src.UpdateRequired > 0 AND
              InvalidID = 0 AND
              StateID IN (3, 4)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
        Begin
            Set @message = 'Removed error messages from the comment field of ' + Cast(@myRowCount as varchar(9)) + dbo.check_plural(@myRowCount, ' dataset', ' datasets')
            Print @message
        End
    End


Done:
    return 0

GO
