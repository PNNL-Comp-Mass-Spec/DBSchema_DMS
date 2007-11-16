/****** Object:  StoredProcedure [dbo].[RequestAnalysisJobPreview] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.RequestAnalysisJobPreview
/****************************************************
**
**	Desc: Calls RequestAnalysisJob to preview the 
**		  jobs that would be returned for the given processor
**
**	Return values: 0: success, otherwise, status code
**
**	Auth:	mem
**	Date:	05/22/2007
**
*****************************************************/
(
	@processorName varchar(128)='seqcluster1',
    @message varchar(512)='' output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @jobID int

	exec @myError = RequestAnalysisJob @processorName=@processorName, @message=@message output, @infoOnly=1

Done:
	if @message <> ''
		Select @message as Status_Message, @myError as Status_Code

	return @myError


GO
GRANT EXECUTE ON [dbo].[RequestAnalysisJobPreview] TO [DMS_User]
GO
