/****** Object:  StoredProcedure [dbo].[SetCaptureTaskBusy] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure SetCaptureTaskBusy
/****************************************************
**
**	Desc: 
**	Sets appropriate dataset state to busy
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: grk
**	Date: 12/15/2009
**  01/14/2010 grk -- removed path ID fields
**    
*****************************************************/
	@datasetNum varchar(128),
	@machineName varchar(64),
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''
 
	UPDATE T_Dataset
	SET 
		DS_state_ID = 2, 
		DS_PrepServerName = @machineName
	WHERE
		Dataset_Num = @datasetNum
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Update operation failed'
	end

	RETURN @myError
GO
GRANT VIEW DEFINITION ON [dbo].[SetCaptureTaskBusy] TO [Limited_Table_Write] AS [dbo]
GO
