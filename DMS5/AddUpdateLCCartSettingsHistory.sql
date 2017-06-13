/****** Object:  StoredProcedure [dbo].[AddUpdateLCCartSettingsHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateLCCartSettingsHistory
/****************************************************
**
**  Desc: Adds new or edits existing T_LC_Cart_Settings_History
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth: 	grk
**  Date: 	09/29/2008
**			10/21/2008 grk - Added parameters @SolventA and @SolventB
**			06/13/2017 mem - Use SCOPE_IDENTITY()
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@ID int,
	@CartName varchar(128),
	@ValveToColumnExtension varchar(128),
	@OperatingPressure varchar(128),
	@InterfaceConfiguration varchar(128),
	@ValveToColumnExtensionDimensions varchar(128),
	@MixerVolume varchar(128),
	@SampleLoopVolume varchar(128),
	@SampleLoadingTime varchar(128),
	@SplitFlowRate varchar(128),
	@SplitColumnDimensions varchar(128),
	@PurgeFlowRate varchar(128),
	@PurgeColumnDimensions varchar(128),
	@PurgeVolume varchar(128),
	@AcquisitionTime varchar(128),
	@SolventA varchar(128),
	@SolventB varchar(128),
	@Comment varchar(512),
	@DateOfChange varchar(24),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	-- future: this could get more complicated

	---------------------------------------------------
	-- Resolve cart name to ID
	---------------------------------------------------
	declare @cartID int
	set @cartID = 0
	--
	SELECT @cartID = ID
	FROM  T_LC_Cart
	WHERE Cart_Name = @CartName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to resolve cart ID'
		RAISERROR (@message, 10, 1)
		return 51007
    end

	if @cartID = 0
	begin
		set @message = 'Could not find cart'
		RAISERROR (@message, 10, 1)
		return 51006
    end


	---------------------------------------------------
	-- Is entry already in database? (only applies to updates)
	---------------------------------------------------

	if @mode = 'update'
	begin
		-- cannot update a non-existent entry
		--
		declare @tmp int = 0
		--
		SELECT @tmp = ID
		FROM T_LC_Cart_Settings_History
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 OR @tmp = 0
		begin
			set @message = 'No entry could be found in database for update'
			RAISERROR (@message, 10, 1)
			return 51007
		end

	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

		INSERT INTO T_LC_Cart_Settings_History ( 
			Valve_To_Column_Extension,
			Operating_Pressure,
			Interface_Configuration,
			Valve_To_Column_Extension_Dimensions,
			Mixer_Volume,
			Sample_Loop_Volume,
			Sample_Loading_Time,
			Split_Flow_Rate,
			Split_Column_Dimensions,
			Purge_Flow_Rate,
			Purge_Column_Dimensions,
			Purge_Volume,
			Acquisition_Time,
			Solvent_A,
			Solvent_B,
			Cart_ID,
			[Comment],
			Date_Of_Change,
			EnteredBy
		) VALUES (
			@ValveToColumnExtension, 
			@OperatingPressure, 
			@InterfaceConfiguration,
			@ValveToColumnExtensionDimensions, 
			@MixerVolume, 
			@SampleLoopVolume, 
			@SampleLoadingTime,
			@SplitFlowRate, 
			@SplitColumnDimensions, 
			@PurgeFlowRate, 
			@PurgeColumnDimensions,
			@PurgeVolume, 
			@AcquisitionTime, 
			@SolventA, 
			@SolventB, 
			@cartID, 
			@Comment, 
			@DateOfChange,
			@callingUser
		)

		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Insert operation failed'
			RAISERROR (@message, 10, 1)
			return 51007
		end
	    
		-- Return ID of newly created entry
		--
		set @ID = SCOPE_IDENTITY()

	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		UPDATE T_LC_Cart_Settings_History
		SET Valve_To_Column_Extension = @ValveToColumnExtension,
		    Operating_Pressure = @OperatingPressure,
		    Interface_Configuration = @InterfaceConfiguration,
		    Valve_To_Column_Extension_Dimensions = @ValveToColumnExtensionDimensions,
		    Mixer_Volume = @MixerVolume,
		    Sample_Loop_Volume = @SampleLoopVolume,
		    Sample_Loading_Time = @SampleLoadingTime,
		    Split_Flow_Rate = @SplitFlowRate,
		    Split_Column_Dimensions = @SplitColumnDimensions,
		    Purge_Flow_Rate = @PurgeFlowRate,
		    Purge_Column_Dimensions = @PurgeColumnDimensions,
		    Purge_Volume = @PurgeVolume,
		    Acquisition_Time = @AcquisitionTime,
		    Solvent_A = @SolventA,
		    Solvent_B = @SolventB,
		    COMMENT = @Comment,
		    Date_Of_Change = @DateOfChange,
		    EnteredBy = @callingUser
		WHERE (ID = @ID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Update operation failed: "' + @ID + '"'
			RAISERROR (@message, 10, 1)
			return 51004
		end
	end -- update mode

  return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCCartSettingsHistory] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLCCartSettingsHistory] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCCartSettingsHistory] TO [Limited_Table_Write] AS [dbo]
GO
