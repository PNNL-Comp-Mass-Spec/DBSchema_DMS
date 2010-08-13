/****** Object:  StoredProcedure [dbo].[SetPrepLCTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure SetPrepLCTaskComplete
/****************************************************
**
**	Desc:
**      Sets state of prepLCRun according to capture
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: grk
**	05/08/2010
**    
*****************************************************/
(
	@ID INT,
	@storagePathID INT,
	@completionCode int = 0, -- @completionCode = 0 -> success, @completionCode = 1 -> failure
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	IF @completionCode = 0
	BEGIN
		UPDATE 
			T_Prep_LC_Run
		SET 
			Uploaded = GETDATE(),
			Storage_Path = CASE WHEN Storage_Path IS NULL THEN @storagePathID ELSE Storage_Path END
		WHERE 
			ID = @ID
		
	END

GO
GRANT EXECUTE ON [dbo].[SetPrepLCTaskComplete] TO [DMS2_SP_User] AS [dbo]
GO
