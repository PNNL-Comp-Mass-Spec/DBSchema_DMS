/****** Object:  UserDefinedFunction [dbo].[GetDatasetPMTaskCount] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.GetDatasetPMTaskCount
/****************************************************
**
**	Desc: Returns a count of the number of peak matching tasks for this dataset
**
**	Auth:	mem
**	Date:	07/25/2017 mem - Initial version
**    
*****************************************************/
(
	@datasetID INT
)
RETURNS int
AS
BEGIN
	DECLARE @result int

	SELECT @result = COUNT(*)
    FROM dbo.T_Analysis_Job AS AJ
        INNER JOIN dbo.T_MTS_Peak_Matching_Tasks_Cached AS PM
            ON AJ.AJ_jobID = PM.DMS_Job
    WHERE AJ.AJ_datasetID = @datasetID

	RETURN IsNull(@result, 0)
END

GO
GRANT VIEW DEFINITION ON [dbo].[GetDatasetPMTaskCount] TO [DDL_Viewer] AS [dbo]
GO
