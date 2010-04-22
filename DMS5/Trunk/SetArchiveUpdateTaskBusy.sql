/****** Object:  StoredProcedure [dbo].[SetArchiveUpdateTaskBusy] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure SetArchiveUpdateTaskBusy
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
**    
*****************************************************/
	@datasetNum varchar(128),
	@StorageServerName VARCHAR(64),
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = '' 
	
	UPDATE
		T_Dataset_Archive
	SET
		AS_update_state_ID = 3,
		AS_update_processor = @StorageServerName
	FROM
		T_Dataset_Archive
		INNER JOIN T_Dataset ON T_Dataset.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID
	WHERE
		T_Dataset.Dataset_Num = @datasetNum		
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Update operation failed'
	end

	RETURN @myError
GO
