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
       AJ.AJ_requestID AS Request,
       AJ.AJ_created AS Created,
       AJ.AJ_start AS Start,
       AJ.AJ_finish AS Finish,
       AJ.Aj_assignedProcessorName as Processor,
       DS.Dataset_Num AS Dataset
	FROM T_Analysis_Job AJ
		INNER JOIN GetRunRequestExistingJobListTab (@requestID) M ON M.job = AJ.AJ_jobID
		INNER JOIN T_Analysis_State_Name ASN ON AJ.AJ_StateID = ASN.AJS_stateID
		INNER JOIN T_Dataset DS ON AJ.AJ_DatasetID = DS.Dataset_ID
	ORDER BY AJ.AJ_jobID Desc

Done:
	RETURN @myError


GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForRequest] TO [DMS_Guest]
GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForRequest] TO [DMS_User]
GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForRequest] TO [DMS2_SP_User]
GO
