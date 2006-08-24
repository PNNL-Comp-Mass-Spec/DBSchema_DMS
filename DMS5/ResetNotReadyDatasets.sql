/****** Object:  StoredProcedure [dbo].[ResetNotReadyDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE ResetNotReadyDatasets
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
**		Auth: grk
**		Date: 8/6/2003
**    
*****************************************************/
@interval int = 10
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
	declare @targetState int
	set @targetState = 9 -- 'not ready' state


	UPDATE M   
	SET	M.DS_state_ID = 1 -- 'new' state
	FROM T_Dataset M
	Inner Join 
	(
		SELECT Target_ID AS DatasetID
		FROM T_Event_Log
		WHERE (Target_Type = 4) AND (Target_State = @targetState)
		GROUP BY Target_ID
		HAVING (DATEDIFF(mi, MAX(Entered), GETDATE()) > @interval)
	) T on T.DatasetID = M.Dataset_ID
	WHERE     (DS_state_ID = @targetState)
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
