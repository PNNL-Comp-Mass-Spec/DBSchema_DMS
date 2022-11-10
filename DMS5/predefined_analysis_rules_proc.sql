/****** Object:  StoredProcedure [dbo].[predefined_analysis_rules_proc] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[predefined_analysis_rules_proc]
/****************************************************
** 
**  Desc: 
**     Get the predefined analysis rules for given dataset
**     Return a table listing the rules that would be evaluated
**
**  Auth:   mem
**  Date:   11/08/2022 mem - Initial version
**
*****************************************************/
(
    @datasetName varchar(128),
    @message varchar(512) = '' output,
    @ExcludeDatasetsNotReleased tinyint = 1,        -- When non-zero, excludes datasets with a rating of -5 (by default we exclude datasets with a rating < 2 and <> -10)
    @AnalysisToolNameFilter varchar(128) = ''       -- If not blank, then only considers predefines that match the given tool name (can contain wildcards)
)
As
    Set nocount on
    
    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    Set @message = ''
    Set @datasetName = IsNull(@datasetName, '')
    Set @ExcludeDatasetsNotReleased = IsNull(@ExcludeDatasetsNotReleased, 1)
    Set @AnalysisToolNameFilter = IsNull(@AnalysisToolNameFilter, '')
    
    Exec @myError = EvaluatePredefinedAnalysisRules 
                        @datasetName, 
                        'Show Rules',
                        @message = @message Output,
                        @RaiseErrorMessages = 1,
                        @ExcludeDatasetsNotReleased = @ExcludeDatasetsNotReleased,
                        @CreateJobsForUnreviewedDatasets = 1,
                        @AnalysisToolNameFilter = @AnalysisToolNameFilter;   

    Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[predefined_analysis_rules_proc] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[predefined_analysis_rules_proc] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[predefined_analysis_rules_proc] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[predefined_analysis_rules_proc] TO [Limited_Table_Write] AS [dbo]
GO
