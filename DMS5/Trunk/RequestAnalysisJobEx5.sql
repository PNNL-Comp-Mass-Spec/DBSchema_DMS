/****** Object:  StoredProcedure [dbo].[RequestAnalysisJobEx5] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.RequestAnalysisJobEx5
/****************************************************
**
**	Desc: This is a wrapper that presents the analysis 
**        manager with its current interface, but calls
**        the new version of the stored procedure
**
**	Return values: 0: success, otherwise, error code
**
**
**		Auth: grk
**		Date: 02/14/2007 (Ticket #382)
**			  02/23/2007 grk - Accomodate modified RequestAnalysisJob sproc.
**    
**
*****************************************************/
	@toolName varchar(64) = '',
	@processorName varchar(64),
	@requestedPriority int = 0,
	@requestedMinDuration float = 0,
	@requestedMaxDuration float = 99000,

	@jobNum varchar(32) output,
	@datasetNum varchar(64) = '' output,
	@datasetFolderName varchar(128) = '' output,
	@datasetFolderStoragePath varchar(255) = '' output,
	@transferFolderPath varchar(255) = '' output,

	@parmFileName varchar(255) = '' output,
	@parmFileStoragePath varchar(255) = '' output,

	@settingsFileName varchar(64) = '' output,
	@settingsFileStoragePath varchar(255) = '' output,

	@organismDBName varchar(64) = '' output,
	@organismDBStoragePath varchar(255) = '' output,

	@instClass varchar(32) = '' output,

	@comment varchar(255) = '' output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
    declare @message varchar(255)
	set @message = ''

	declare @jobID int
	
	exec @myError = RequestAnalysisJob		
							@processorName,
							@jobNum output,
							@message output,
							0

	return @myError

GO
GRANT EXECUTE ON [dbo].[RequestAnalysisJobEx5] TO [DMS_Analysis_Job_Runner]
GO
GRANT EXECUTE ON [dbo].[RequestAnalysisJobEx5] TO [DMS_SP_User]
GO
