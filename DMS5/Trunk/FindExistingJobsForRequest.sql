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
		DS.Dataset_Num AS Dataset,
		AJPG.Group_Name AS "Processor Group",
		AJPG.Entered_By AS "Processor Group Assignee"
	FROM dbo.T_Analysis_Job_Processor_Group AJPG
		INNER JOIN dbo.T_Analysis_Job_Processor_Group_Associations AJPGA
		    ON AJPG.ID = AJPGA.Group_ID
		RIGHT OUTER JOIN dbo.T_Analysis_Job AJ
						INNER JOIN dbo.GetRunRequestExistingJobListTab (@requestID) M
							ON M.job = AJ.AJ_jobID
						INNER JOIN dbo.T_Analysis_State_Name ASN
							ON AJ.AJ_StateID = ASN.AJS_stateID
						INNER JOIN dbo.T_Dataset DS
							ON AJ.AJ_datasetID = DS.Dataset_ID
		ON AJPGA.Job_ID = AJ.AJ_jobID
	ORDER BY AJ.AJ_jobID DESC

Done:
	RETURN @myError


GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForRequest] TO [DMS_Guest]
GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForRequest] TO [DMS_User]
GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForRequest] TO [DMS2_SP_User]
GO
