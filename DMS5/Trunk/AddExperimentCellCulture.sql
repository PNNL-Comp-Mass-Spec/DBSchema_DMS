/****** Object:  StoredProcedure [dbo].[AddExperimentCellCulture] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure AddExperimentCellCulture
/****************************************************
**
**	Desc: Adds cell cultures entries to DB for
**        given experiment
**
**	Return values: 0: success, otherwise, error code
**
**		Auth: grk
**		Date: 03/27/2002
**            12/21/2009 grk - commented out requirement that cell cultures belong to same campaign
**    
*****************************************************/

	@expID int,
	@cellCultureList varchar(200) = Null,
	@message varchar(255) = '' output
As		
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	declare @delim char(1)
	set @delim = ';'

	declare @done int
	declare @count int
	
	declare @msg varchar(256)

	--
	declare @mPos int
	set @mPos = 1
	declare @mFld varchar(128)
	--
		
	declare @cellCultureID int
	declare @cellCultureCampaignID int
	
	-- get campaign for experiment
	--
	declare @campaignID int
	set @campaignID = 0
	--
	SELECT @campaignID = EX_campaign_ID
	FROM T_Experiments
	WHERE (Exp_ID = @expID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myRowCount <> 1 or @myError <> 0
	begin
		set @message = 'Could not get campaign ID for experiment'
		return 51059
	end
	
	-- first get rid of any existing entries
	--
	DELETE FROM T_Experiment_Cell_Cultures WHERE (Exp_ID = @expID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Delete was unsuccessful for experiment cell culture table'
		return 51060
	end
	
	-- if list is empty, we are done
	--
	if LEN(@cellCultureList) = 0
		return 0

	-- process list
	-- and insert into DB table
	--
	set @count = 0
	set @done = 0

	while @done = 0
	begin
		set @count = @count + 1
		--print '========== row:' +  + convert(varchar, @count)

		-- process the next field from the media list
		execute @done = NextField @cellCultureList, @delim, @mPos output, @mFld output
		--
		SELECT 
			@cellCultureID = CC_ID,
			@cellCultureCampaignID = CC_Campaign_ID
		FROM T_Cell_Culture 
		WHERE (CC_Name = @mFld)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @cellCultureID = 0
		begin
			set @message = 'Cell culture name could not be found'
			return 51061
		end
/*	grk 12/21/2009
		-- verify that campaigns match
		--
		if ((@cellCultureCampaignID <> @campaignID) and @mFld <> '(none)')
		begin
			set @message = 'Campaign for cell culture "' +  @mFld + '" does not match experiment' + 
			+ '  E:' + cast(@campaignID as varchar(12)) + ', CC:' + cast(@cellCultureCampaignID as varchar(12))
			return 51069
		end
*/
		-- process row into table
		--
		INSERT INTO T_Experiment_Cell_Cultures
		   (Exp_ID, CC_ID)
		VALUES 
			(@expID,@cellCultureID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myRowCount <> 1 or @myError <> 0
		begin
			set @message = 'Insert was unsuccessful for experiment cell culture table'
			return 51062
		end
	end
	
	return 0
GO
GRANT EXECUTE ON [dbo].[AddExperimentCellCulture] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddExperimentCellCulture] TO [DMS_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddExperimentCellCulture] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddExperimentCellCulture] TO [PNL\D3M580] AS [dbo]
GO
