/****** Object:  StoredProcedure [dbo].[SetUpdateRequiredForRunningManagers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SetUpdateRequiredForRunningManagers]
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
**    
*****************************************************/
(
	@infoOnly tinyint = 0,
	@message varchar(512) = '' output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @message = ''
	
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
