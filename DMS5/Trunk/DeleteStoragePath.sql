/****** Object:  StoredProcedure [dbo].[DeleteStoragePath] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure DeleteStoragePath
/****************************************************
**
**	Desc: 
**  Deletes given storage path from the storage path table
**  Storage path may not have any associated datasets.
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: grk
**		Date: 3/14/2006
**    
*****************************************************/
(
	@pathID int,
    @message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
		
	declare @result int


	---------------------------------------------------
	-- verify no associated datasets
	---------------------------------------------------
	declare @cn int
	--
	SELECT @cn = COUNT(*)
	FROM T_Dataset
	WHERE (DS_storage_path_ID = @pathID)	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		RAISERROR ('Error while trying to find associated datasets', 10, 1)
		return 51131
	end
	
	if @cn <> 0
	begin
		RAISERROR ('Cannot delete storage path that is being used by existing datasets', 10, 1)
		return 51132
	end
	

	---------------------------------------------------
	-- delete storage path from table
	---------------------------------------------------
	
	DELETE FROM t_storage_path
	WHERE     (SP_path_ID = @pathID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		RAISERROR ('Delete from storage path table was unsuccessful', 10, 1)
		return 51130
	end
	
	return @myError

GO
