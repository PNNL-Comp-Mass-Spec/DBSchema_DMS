/****** Object:  StoredProcedure [dbo].[AddUpdateSamplePrepRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateSamplePrepRequest
/****************************************************
**
**  Desc: Adds new or edits existing SamplePrepRequest
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 06/09/2005
**          06/10/2005  grk - added Reason argument
**          06/16/2005  grk - added state restriction for update
**          07/26/2005  grk - added stuff for requested personnel
**          08/09/2005  grk - widened @SampleNameList
**          10/12/2005  grk - added @UseSingleLCColumn
**          10/26/2005  grk - disallowed change if not in 'New" state
**          10/28/2005  grk - added handling for internal standard
**          11/01/2005  grk - rescinded disallowed change in 'New' state
**          11/11/2005  grk - added handling for postdigest internal standard
**          01/03/2006  grk - added check for existing request name
**          03/14/2006  grk - added stuff for multiple assigned users
**          08/10/2006  grk - modified state handling
**          08/10/2006  grk - allowed multiple requested personnel users
**          12/15/2006  grk - added EstimatedMSRuns argument (Ticket #336)
**          04/20/2007  grk - added validation for organism, campaign, cell culture (Ticket #440)
**    
*****************************************************/
  @RequestName varchar(128),
  @RequesterPRN varchar(32),
  @Reason varchar(512),
  @CellCultureList varchar(256),
  @Organism varchar(128),
  @BiohazardLevel varchar(12),
  @Campaign varchar(128),
  @NumberofSamples int,
  @SampleNameList varchar(1500),
  @SampleType varchar(128),
  @PrepMethod varchar(512),
  @PrepByRobot varchar(8),
  @SpecialInstructions varchar(1024),
  @SampleNamingConvention varchar(128),
  @AssignedPersonnel varchar(256),
  @RequestedPersonnel varchar(256),
  @EstimatedCompletion varchar(32),
  @EstimatedMSRuns varchar(16),
  @WorkPackageNumber varchar(64),
  @UserProposalNumber varchar(64),
  @ReplicatesofSamples varchar(512),
  @InstrumentAnalysisSpecifications varchar(512),
  @Comment varchar(1024),
  @Priority tinyint,
  @State varchar(32),
  @UseSingleLCColumn varchar(50),
  @internalStandard varchar(50),
  @postdigestIntStd varchar(50),
  @ID int output,
  @mode varchar(12) = 'add', -- or 'update'
  @message varchar(512) output
As
  set nocount on

  declare @myError int
  set @myError = 0

  declare @myRowCount int
  set @myRowCount = 0
  
  set @message = ''

  declare @currentStateID int


  ---------------------------------------------------
  -- Validate input fields
  ---------------------------------------------------

  -- future: this could get more complicated
  
	---------------------------------------------------
	-- Resolve campaign ID
	---------------------------------------------------

	declare @campaignID int
	execute @campaignID = GetCampaignID @Campaign
	if @campaignID = 0
	begin
		set @message = 'Could not find entry in database for campaignNum "' + @Campaign + '"'
		RAISERROR (@message, 10, 1)
		return 51036
	end

	---------------------------------------------------
	-- Resolve cell cultures
	---------------------------------------------------

	-- create tempoary table to hold names of cell cultures as input
	--
	create table #CC (
		name varchar(128) not null
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not create temporary table for cell culture list'
		RAISERROR (@message, 10, 1)
		return 51078
	end

	-- get names of cell cultures from list argument into table
	--
	insert into #CC (name) 
	select item from MakeTableFromListDelim(@cellCultureList, ';')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not populate temporary table for cell culture list'
		RAISERROR (@message, 10, 1)
		return 51079
	end

	-- verify that cell cultures exist
	--
	declare @cnt int
	set @cnt = -1
	SELECT @cnt = count(*) 
	FROM #CC 
	WHERE [name] not in (
		SELECT CC_Name
		FROM	T_Cell_Culture
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Was not able to check for cell cultures in database'
		RAISERROR (@message, 10, 1)
		return 51080
	end
	--
	if @cnt <> 0 
	begin
		set @message = 'One or more cell cultures was not in database'
		RAISERROR (@message, 10, 1)
		return 51081	
	end

	---------------------------------------------------
	-- Resolve organism ID
	---------------------------------------------------

	declare @organismID int
	execute @organismID = GetOrganismID @Organism
	if @organismID = 0
	begin
		set @message = 'Could not find entry in database for organismName "' + @Organism + '"'
		RAISERROR (@message, 10, 1)
		return 51038
	end

  ---------------------------------------------------
  -- convert estimated completion date
  ---------------------------------------------------
  declare @EstimatedCompletionDate datetime
  
  if @EstimatedCompletion <> ''
  begin
  	set @EstimatedCompletionDate = CONVERT(datetime, @EstimatedCompletion)
  end
  
  ---------------------------------------------------
  -- force values of some properties for add mode
  ---------------------------------------------------
  
	if @mode = 'add'
	begin
		set @State = 'New'
		set @AssignedPersonnel = 'na'
	end

  ---------------------------------------------------
  -- Convert state name to ID
  ---------------------------------------------------
	declare @StateID int
	set @StateID = 0
	--
	SELECT  @StateID = State_ID
	FROM  T_Sample_Prep_Request_State_Name
	WHERE (State_Name = @State)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error trying to resolving state name'
      RAISERROR (@message, 10, 1)
      return  @myError
    end
    --
    if @StateID = 0
    begin
      set @message = 'No entry could be found in database for state'
      RAISERROR (@message, 10, 1)
      return  50223
    end
    
 	---------------------------------------------------
	-- Resolve internal standard ID
	---------------------------------------------------

	declare @internalStandardID int
	set @internalStandardID = 0
	--
	SELECT @internalStandardID = Internal_Std_Mix_ID
	FROM T_Internal_Standards
	WHERE (Name = @internalStandard)
	--
	if @internalStandardID = 0
	begin
		set @message = 'Could not find entry in database for predigestion internal standard "' + @internalStandard + '"'
		RAISERROR (@message, 10, 1)
		return 51009
	end

	---------------------------------------------------
	-- Resolve postdigestion internal standard ID
	---------------------------------------------------
	-- 
	declare @postdigestIntStdID int
	set @postdigestIntStdID = 0
	--
	SELECT @postdigestIntStdID = Internal_Std_Mix_ID
	FROM T_Internal_Standards
	WHERE (Name = @postdigestIntStd)
	--
	if @postdigestIntStdID = 0
	begin
		set @message = 'Could not find entry in database for postdigestion internal standard "' + @postdigestIntStdID + '"'
		RAISERROR (@message, 10, 1)
		return 51009
	end

  ---------------------------------------------------
  -- Is entry already in database?
  ---------------------------------------------------

  if @mode = 'update'
  begin
    -- cannot update a non-existent entry
    --
	declare @tmp int
	set @tmp = 0
	set @currentStateID = 0
	--
	SELECT @tmp = ID, @currentStateID = State
	FROM  T_Sample_Prep_Request
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

	-- changes not allowed if in "closed" state
	--
    if @currentStateID = 5
    begin
      set @message = 'Changes to entry are not allowed if it is in the "Closed" state'
      RAISERROR (@message, 10, 1)
      return 51008
    end
  end
  
  if @mode = 'add'
  begin
    -- name must be unique
    --
	SELECT *
	FROM T_Sample_Prep_Request
	WHERE (Request_Name = @RequestName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0 OR @myRowCount> 0
    begin
      set @message = 'Cannot add: Request "' + @RequestName + '" already in database '
      RAISERROR (@message, 10, 1)
      return 51008
    end
  end

  ---------------------------------------------------
  -- action for add mode
  ---------------------------------------------------
  if @Mode = 'add'
  begin
 
  INSERT INTO T_Sample_Prep_Request (
    Request_Name, 
    Requester_PRN, 
    Reason,
    Cell_Culture_List, 
    Organism, 
    Biohazard_Level, 
    Campaign, 
    Number_of_Samples, 
    Sample_Name_List, 
    Sample_Type, 
    Prep_Method, 
    Prep_By_Robot, 
    Special_Instructions, 
    Sample_Naming_Convention, 
    Requested_Personnel,
    Assigned_Personnel, 
    Estimated_Completion,
    Estimated_MS_runs,
    Work_Package_Number, 
    User_Proposal_Number, 
    Replicates_of_Samples, 
    Instrument_Analysis_Specifications, 
    Comment, 
    Priority, 
    UseSingleLCColumn,
    Internal_standard_ID, 
    Postdigest_internal_std_ID,
    State
  ) VALUES (
    @RequestName, 
    @RequesterPRN, 
	@Reason,
    @CellCultureList, 
    @Organism, 
    @BiohazardLevel, 
    @Campaign, 
    @NumberofSamples, 
    @SampleNameList, 
    @SampleType, 
    @PrepMethod, 
    @PrepByRobot, 
    @SpecialInstructions, 
    @SampleNamingConvention, 
    @RequestedPersonnel,
    @AssignedPersonnel, 
    @EstimatedCompletionDate,
    @EstimatedMSRuns,
    @WorkPackageNumber, 
    @UserProposalNumber, 
    @ReplicatesofSamples, 
    @InstrumentAnalysisSpecifications, 
	@Comment, 
    @Priority, 
    @UseSingleLCColumn,
    @InternalstandardID, 
    @postdigestIntStdID,
    @StateID
  )
/**/
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Insert operation failed'
      RAISERROR (@message, 10, 1)
      return 51007
    end
    
    -- return IDof newly created entry
    --
    set @ID = IDENT_CURRENT('T_Sample_Prep_Request')

  end -- add mode

  ---------------------------------------------------
  -- action for update mode
  ---------------------------------------------------
  --
  if @Mode = 'update' 
  begin
    set @myError = 0
    --

    UPDATE T_Sample_Prep_Request 
    SET 
      Request_Name = @RequestName, 
      Requester_PRN = @RequesterPRN, 
      Reason = @Reason,
      Cell_Culture_List = @CellCultureList, 
      Organism = @Organism, 
      Biohazard_Level = @BiohazardLevel, 
      Campaign = @Campaign, 
      Number_of_Samples = @NumberofSamples, 
      Sample_Name_List = @SampleNameList, 
      Sample_Type = @SampleType, 
      Prep_Method = @PrepMethod, 
      Prep_By_Robot = @PrepByRobot, 
      Special_Instructions = @SpecialInstructions, 
      Sample_Naming_Convention = @SampleNamingConvention, 
      Requested_Personnel = @RequestedPersonnel,
      Assigned_Personnel = @AssignedPersonnel, 
      Estimated_Completion = @EstimatedCompletionDate,
      Estimated_MS_runs = @EstimatedMSRuns,
      Work_Package_Number = @WorkPackageNumber, 
      User_Proposal_Number = @UserProposalNumber, 
      Replicates_of_Samples = @ReplicatesofSamples, 
      Instrument_Analysis_Specifications = @InstrumentAnalysisSpecifications, 
      Comment = @Comment, 
      Priority = @Priority, 
      UseSingleLCColumn = @UseSingleLCColumn,
      Internal_standard_ID = @InternalstandardID, 
      Postdigest_internal_std_ID = @postdigestIntStdID,
   State = @StateID
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
GRANT EXECUTE ON [dbo].[AddUpdateSamplePrepRequest] TO [DMS_User]
GO
