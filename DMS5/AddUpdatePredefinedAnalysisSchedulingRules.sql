/****** Object:  StoredProcedure [dbo].[AddUpdatePredefinedAnalysisSchedulingRules] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE AddUpdatePredefinedAnalysisSchedulingRules
/****************************************************
**
**  Desc: Adds new or edits existing T_Predefined_Analysis_Scheduling_Rules
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 06/23/2005
**    
*****************************************************/
  @evaluationOrder smallint,
  @instrumentClass varchar(32),
  @instrumentName varchar(64),
  @datasetName varchar(128),
  @analysisToolName varchar(64),
  @priority int,
  @processorName varchar(64),
  @enabled tinyint,
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

  ---------------------------------------------------
  -- Validate input fields
  ---------------------------------------------------

  -- future: this could get more complicated
  

  ---------------------------------------------------
  -- Is entry already in database? (only applies to updates)
  ---------------------------------------------------

  if @mode = 'update'
  begin
    -- cannot update a non-existent entry
    --
    declare @tmp int
	set @tmp = 0
	--
	SELECT @tmp = ID
	FROM  T_Predefined_Analysis_Scheduling_Rules
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
 
  INSERT INTO T_Predefined_Analysis_Scheduling_Rules (
    SR_evaluationOrder, 
    SR_instrumentClass, 
    SR_instrument_Name, 
    SR_dataset_Name, 
    SR_analysisToolName, 
    SR_priority, 
    SR_processorName, 
    SR_enabled
  ) VALUES (
    @evaluationOrder, 
    @instrumentClass, 
    @instrumentName, 
    @datasetName, 
    @analysisToolName, 
    @priority, 
    @processorName, 
    @enabled
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
    set @ID = IDENT_CURRENT('T_Predefined_Analysis_Scheduling_Rules')

  end -- add mode

  ---------------------------------------------------
  -- action for update mode
  ---------------------------------------------------
  --
  if @Mode = 'update' 
  begin
    set @myError = 0
    --

    UPDATE T_Predefined_Analysis_Scheduling_Rules 
    SET 
      SR_evaluationOrder = @evaluationOrder, 
      SR_instrumentClass = @instrumentClass, 
      SR_instrument_Name = @instrumentName, 
      SR_dataset_Name = @datasetName, 
      SR_analysisToolName = @analysisToolName, 
      SR_priority = @priority, 
      SR_processorName = @processorName, 
      SR_enabled = @enabled
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
GRANT EXECUTE ON [dbo].[AddUpdatePredefinedAnalysisSchedulingRules] TO [DMS_Analysis]
GO
