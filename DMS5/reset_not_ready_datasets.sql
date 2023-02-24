/****** Object:  StoredProcedure [dbo].[ResetNotReadyDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.ResetNotReadyDatasets
/****************************************************
**
**	Desc: 
**		Checks all datasets that are in "Not Ready" state
**		and resets them to "New" 
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**	Auth:	grk
**	Date:	08/06/2003
**			05/16/2007 mem - Updated to use DS_Last_Affected (Ticket:478)
**			01/30/2017 mem - Switch from DateDiff to DateAdd
**    
*****************************************************/
(
	@interval int = 10		-- Minutes between retries
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	declare @message varchar(512)
	set @message = ''

	---------------------------------------------------
	-- Reset all datasets that are in "Not Ready" state
	---------------------------------------------------
	
	-- update to 'new' state all datasets that are in the target state
	-- and have been in that state at least for the required interval
	--
	declare @StateNotReady int
	set @StateNotReady = 9	-- 'not ready' state

	declare @StateNew int
	set @StateNew = 1		-- 'new' state
	
	UPDATE T_Dataset
	SET	DS_state_ID = @StateNew
	WHERE DS_state_ID = @StateNotReady AND
	      DS_Last_Affected < DateAdd(minute, -@interval, GetDate())
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = ''
		goto done
	end


Done:
	return


GO
GRANT VIEW DEFINITION ON [dbo].[ResetNotReadyDatasets] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ResetNotReadyDatasets] TO [Limited_Table_Write] AS [dbo]
GO
