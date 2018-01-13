/****** Object:  StoredProcedure [dbo].[FindExistingJobsForRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.FindExistingJobsForRequest
/****************************************************
**
**	Desc: 
**    Check how many existing jobs already exist that
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	12/05/2005
**			04/07/2006 grk - eliminated job to request map table
**			09/10/2007 mem - Now returning columns Processor and Dataset
**			04/09/2008 mem - Now returning associated processor group, if applicable
**			09/03/2008 mem - Fixed bug that returned Entered_By from T_Analysis_Job_Processor_Group instead of from T_Analysis_Job_Processor_Group_Associations
**			05/28/2015 mem - Removed reference to T_Analysis_Job_Processor_Group
**    
*****************************************************/
(
	@requestID int,
	@message varchar(512) output
)
AS
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	SELECT AJ.AJ_jobID AS Job,
		ASN.AJS_name AS State,
		AJ.AJ_priority AS Priority,
		AJ.AJ_requestID AS Request,
		AJ.AJ_created AS Created,
		AJ.AJ_start AS Start,
		AJ.AJ_finish AS Finish,
		AJ.AJ_assignedProcessorName AS Processor,
		DS.Dataset_Num AS Dataset		
	FROM dbo.T_Analysis_Job AJ
		INNER JOIN dbo.GetRunRequestExistingJobListTab (@requestID) M
			ON M.job = AJ.AJ_jobID
		INNER JOIN dbo.T_Analysis_State_Name ASN
			ON AJ.AJ_StateID = ASN.AJS_stateID
		INNER JOIN dbo.T_Dataset DS
			ON AJ.AJ_datasetID = DS.Dataset_ID		
	ORDER BY AJ.AJ_jobID DESC

Done:
	RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[FindExistingJobsForRequest] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForRequest] TO [DMS_Guest] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForRequest] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForRequest] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForRequest] TO [DMSReader] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[FindExistingJobsForRequest] TO [Limited_Table_Write] AS [dbo]
GO
