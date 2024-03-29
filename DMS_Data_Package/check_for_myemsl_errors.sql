/****** Object:  StoredProcedure [dbo].[check_for_myemsl_errors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[check_for_myemsl_errors]
/****************************************************
**
**  Desc: Looks for anomalies in T_MyEMSL_Uploads
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   12/10/2013 mem - Initial version
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          08/17/2023 mem - Use renamed column data_pkg_id in T_MyEMSL_Uploads
**
*****************************************************/
(
    @mostRecentDays int = 2,
    @startDate datetime = null,     -- Only used if @MostRecentDays is 0 or negative
    @endDate datetime = null,       -- Only used if @MostRecentDays is 0 or negative
    @logErrors tinyint = 1,
    @message varchar(255) = '' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    Set @MostRecentDays = IsNull(@MostRecentDays, 0)
    Set @StartDate = IsNull(@StartDate, DateAdd(day, -2, GetDate()))

    Set @EndDate = IsNull(@EndDate, GetDate())
    Set @LogErrors = IsNull(@LogErrors, 1)

    If @MostRecentDays > 0
    Begin
        Set @EndDate = GetDate()
        Set @StartDate = DateAdd(day, -Abs(@MostRecentDays), @EndDate)
    End

    -----------------------------------------------
    -- Query the upload stats
    -----------------------------------------------
    --

    Declare @UploadAttempts int
    Declare @UploadErrors int
    Declare @UploadErrorRate float = 0

    Declare @DataPkgFolderUploads int
    Declare @DuplicateUploads int
    Declare @DuplicateRate float = 0

    SELECT @UploadErrors = COUNT(*)
    FROM T_MyEMSL_Uploads
    WHERE Entered BETWEEN @StartDate AND @EndDate AND
          Bytes > 0 AND
          ErrorCode <> 0
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    SELECT @UploadAttempts = COUNT(*)
    FROM T_MyEMSL_Uploads
    WHERE Entered BETWEEN @StartDate AND @EndDate
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    SELECT @DataPkgFolderUploads = COUNT(*),
           @DuplicateUploads = Sum(CASE
                                       WHEN UploadAttempts > 1 THEN 1
                                       ELSE 0
                                   END)
    FROM ( SELECT Data_Pkg_ID,
                  Subfolder,
                  COUNT(*) AS UploadAttempts
           FROM T_MyEMSL_Uploads
           WHERE Entered BETWEEN @StartDate AND @EndDate
           GROUP BY Data_Pkg_ID, Subfolder
         ) UploadsByDataPkgAndFolder


    If @UploadAttempts > 0
        Set @UploadErrorRate = @UploadErrors / CONVERT(float, @UploadAttempts)

    If @DataPkgFolderUploads > 0
        Set @DuplicateRate = @DuplicateUploads / CONVERT(float, @DataPkgFolderUploads)

    If @UploadErrorRate > 0.01
    Begin
        --
        Set @message = 'More than 1% of the uploads to MyEMSL had an error; error rate: ' + Convert(varchar(12), Convert(int, @UploadErrorRate*100)) + '% for ' + Convert(varchar(12), @UploadAttempts) + ' upload attempts'

        If @LogErrors <> 0
            Exec post_log_entry 'Error', @message, 'check_for_myemsl_errors'
        Else
            Print @message

    End


    If @DuplicateRate > 0.05
    Begin
        --
        Set @message = 'More than 5% of the uploads to MyEMSL involved uploading the same data package and subfolder 2 or more times; duplicate rate: ' + Convert(varchar(12), Convert(int, @DuplicateRate*100)) + '% for ' + Convert(varchar(12), @DataPkgFolderUploads) + ' DataPkg/folder combos'

        If @LogErrors <> 0
            Exec post_log_entry 'Error', @message, 'check_for_myemsl_errors'
        Else
            Print @message

    End

Done:

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[check_for_myemsl_errors] TO [DDL_Viewer] AS [dbo]
GO
