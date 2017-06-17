/****** Object:  StoredProcedure [dbo].[SetUpdateRequiredForRunningManagers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SetUpdateRequiredForRunningManagers
/****************************************************
**
**	Desc: 
**		Sets ManagerUpdateRequired to True in the Manager Control database
**		for currently running managers
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**			04/17/2014 mem - Initial release
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**    
*****************************************************/
(
	@infoOnly tinyint = 0,
	@message varchar(512) = '' output
)
As
	set nocount on
	
	declare @myError int = 0
	declare @myRowCount int = 0
	
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @message = ''

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'RequestStepTaskXML', @raiseError = 1
	If @authorized = 0
	Begin
		RAISERROR ('Access denied', 11, 3)
	End
	
	---------------------------------------------------
	-- Get a list of the currently running managers
	---------------------------------------------------
	--
	Declare @mgrList varchar(max)
	
	SELECT @mgrList = Coalesce(@mgrList + ',', '') + Processor
	FROM T_Job_Steps
	WHERE (State = 4)
	ORDER BY Processor
 	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	Declare @mgrCount int = @myRowCount
	
	If @infoOnly <> 0
	Begin
		Select @mgrList as ManagersNeedingUpdate
	End
	Else
	Begin
		Print 'Calling SetManagerUpdateRequired for ' + Convert(varchar(12), @mgrCount) + ' managers'
		Exec @myError = ProteinSeqs.Manager_Control.dbo.SetManagerUpdateRequired @mgrList, @showTable=1
	End
	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[SetUpdateRequiredForRunningManagers] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[SetUpdateRequiredForRunningManagers] TO [DMS_SP_User] AS [dbo]
GO
