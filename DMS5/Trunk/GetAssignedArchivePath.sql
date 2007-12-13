/****** Object:  StoredProcedure [dbo].[GetAssignedArchivePath] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure GetAssignedArchivePath
/****************************************************
**
**	Desc:
**    Chooses archive path for given instrument and campaign
**
**	Auth: grk 
**	10/09/2007 initial version (http://prismtrac.pnl.gov/trac/ticket/537)
**    
*****************************************************/
	@DatasetID int,
	@ArchivePathID int output,
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

   	---------------------------------------------------
	-- get dataset information
	---------------------------------------------------
	declare @instrumentID int
	--
	SELECT
		@instrumentID = DS_instrument_name_ID
	FROM
		T_Dataset
	WHERE 
		Dataset_ID = @DatasetID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error looking up dataset info'
		goto done
	end
	
   	---------------------------------------------------
	-- get assigned archive path
	---------------------------------------------------
	--
	set @ArchivePathID = 0
	--
	SELECT 
	  @ArchivePathID = AP_path_ID
	FROM   
	  T_Archive_Path
	WHERE  
		(AP_Function = 'Active') AND
		(AP_instrument_name_ID = @instrumentID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error looking up archive path'
		goto done
	end
	--
	if @archivePathID = 0
	begin
		set @myError = 52111
		set @message = 'Could not find assigned archive storage path'
		goto done
	end

   	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
