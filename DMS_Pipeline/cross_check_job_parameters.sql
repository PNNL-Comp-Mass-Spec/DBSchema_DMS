/****** Object:  StoredProcedure [dbo].[cross_check_job_parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[cross_check_job_parameters]
/****************************************************
**
**  Desc: Compares the data in #Job_Steps to existing data in T_Job_Steps
**        to look for incompatibilities
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          02/03/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          03/11/2009 mem - Now including Old/New step tool and Old/New Signatures if differences are found (Ticket #725, http://prismtrac.pnl.gov/trac/ticket/725)
**          01/06/2011 mem - Added parameter @IgnoreSignatureMismatch
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in temporary table
**
*****************************************************/
(
    @job int,
    @message varchar(512) output,
    @ignoreSignatureMismatch tinyint = 0
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    -- cross-check steps against parameter effects
    ---------------------------------------------------
    --
    declare @jobS varchar(12)
    set @jobS = CONVERT(varchar(12), @job)
    --
    SELECT @message = @message +
        CASE WHEN (OJS.Shared_Result_Version = NJS.Shared_Result_Version) THEN '' ELSE
            ' step ' + CONVERT(varchar(12), OJS.Step) + ' Shared_Result_Version ' +
            '(' + CONVERT(varchar(12), OJS.Shared_Result_Version) + '|' + CONVERT(varchar(12), NJS.Shared_Result_Version) + ');'
            END +

        CASE WHEN (OJS.Tool = NJS.Tool) THEN '' ELSE
            ' step ' + CONVERT(varchar(12), OJS.Step) + ' Tool ' +
            '(' + CONVERT(varchar(12), OJS.Tool) + '|' + CONVERT(varchar(12), NJS.Tool) + ');'
            END +

        CASE WHEN (OJS.Signature = NJS.Signature ) OR @IgnoreSignatureMismatch > 0 THEN '' ELSE
            ' step ' + CONVERT(varchar(12), OJS.Step)  + ' Signature ' +
            '(' + CONVERT(varchar(12), OJS.Signature) + '|' + CONVERT(varchar(12), NJS.Signature) + ');'
            END

        -- CASE WHEN (OJS.Output_Folder_Name = NJS.Output_Folder_Name) THEN '' ELSE
        --  ' step ' + CONVERT(varchar(12), OJS.Step) + ' Output_Folder_Name;'  END

    FROM T_Job_Steps OJS
         INNER JOIN #Job_Steps NJS
           ON OJS.Job = NJS.Job AND
              OJS.Step = NJS.Step
    WHERE ((NOT (OJS.Signature IS NULL)) OR
           (NOT (NJS.Signature IS NULL)))

    if @message <> ''
    begin
        set @myError = 99
        set @message = 'Parameter mismatch:' + @message
    end

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[cross_check_job_parameters] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[cross_check_job_parameters] TO [Limited_Table_Write] AS [dbo]
GO
