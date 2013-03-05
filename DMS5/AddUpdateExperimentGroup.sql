/****** Object:  StoredProcedure [dbo].[AddUpdateExperimentGroup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddUpdateExperimentGroup
/****************************************************
**
**  Desc: Adds new or edits existing Experiment Group
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 07/11/2006
**			09/13/2011 grk - Added Researcher
**			11/10/2011 grk - Removed character size limit from experiment list
**			11/10/2011 grk - Added Tab field
**			02/20/2013 mem - Now reporting invalid experiment names
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
  @ID int output,
  @GroupType varchar(50),
  @Tab VARCHAR(128),
  @Description varchar(512),
  @ExperimentList varchar(MAX),
  @ParentExp varchar(50),
  @Researcher VARCHAR(50),
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
  -- Resolve parent experiment name to ID
  ---------------------------------------------------

  declare @ParentExpID int
  set @ParentExpID = 0
  --
  if @ParentExp <> ''
  begin
    ---
    select @ParentExpID = Exp_ID
    from T_Experiments
    where Experiment_Num = @ParentExp
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error trying to find existing entry'
      RAISERROR (@message, 10, 1)
      return 51004
    end
  end
  
  if @ParentExpID = 0
  begin
	  set @ParentExpID = 15 -- "Placeholder" experiment NOTE: better to look it up
  end

  ---------------------------------------------------
  -- Is entry already in database? (only applies to updates)
  ---------------------------------------------------
  declare @tmp int

  if @mode = 'update'
  begin
    -- cannot update a non-existent entry
    --
    set @tmp = 0
    --
    SELECT @tmp = Group_ID
    FROM  T_Experiment_Groups
    WHERE (Group_ID = @ID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error trying to find existing entry'
      RAISERROR (@message, 10, 1)
      return 51004
    end

    if @tmp = 0
    begin
      set @message = 'Cannot update: entry does not exits in database'
      RAISERROR (@message, 10, 1)
      return 51004
    end
  end

  ---------------------------------------------------
  -- create temporary table for experiments in list
  ---------------------------------------------------
  --
  CREATE TABLE #XR (
    Experiment_Num varchar(50),
    Exp_ID int
  ) 
  --
  SELECT @myError = @@error, @myRowCount = @@rowcount
  --
  if @myError <> 0
  begin
    set @message = 'Failed to create temporary table for experiments'
    RAISERROR (@message, 10, 1)
    return 51219
  end

  ---------------------------------------------------
  -- populate temporary table from list
  ---------------------------------------------------
  --
  INSERT INTO #XR (Experiment_Num, Exp_ID)
  SELECT cast(Item as varchar(50)), 0
  FROM dbo.MakeTableFromList(@ExperimentList)
  --
  SELECT @myError = @@error, @myRowCount = @@rowcount
  --
  if @myError <> 0
  begin
    set @message = 'Failed to populate temporary table for experiments'
    RAISERROR (@message, 10, 1)
    return 51219
  end


  ---------------------------------------------------
  -- resolve experiment name to ID in temp table
  ---------------------------------------------------
  
  UPDATE T
  SET T.Exp_ID = S.Exp_ID
  FROM #XR T
       INNER JOIN T_Experiments S
         ON T.Experiment_Num = S.Experiment_Num

  --
  SELECT @myError = @@error, @myRowCount = @@rowcount
  --
  if @myError <> 0
  begin
    set @message = 'Failed trying to resolve experiment IDs'
    RAISERROR (@message, 10, 1)
    return 51219
  end

  ---------------------------------------------------
  -- check status of prospective member experiments
  ---------------------------------------------------
  declare @count int
  
  -- do all experiments in list actually exist?
  --
  set @count = 0
  --
  SELECT @count = count(*)
  FROM #XR
  WHERE Exp_ID = 0
  --
  SELECT @myError = @@error, @myRowCount = @@rowcount
  --
  if @myError <> 0
  begin
    set @message = 'Failed trying to check existence of experiments in list'
    RAISERROR (@message, 10, 1)
    return 51219
  end

  if @count <> 0
  begin
	Declare @InvalidExperiments varchar(256) = ''
    SELECT @InvalidExperiments = @InvalidExperiments + Experiment_Num + ','
    FROM #XR
    WHERE Exp_ID = 0
	
	-- Remove the trailing comma
	If @InvalidExperiments Like '%,'
		Set @InvalidExperiments = Substring(@InvalidExperiments, 1, Len(@InvalidExperiments)-1)
		
    set @message = 'experiment run list contains experiments that do not exist: ' + @InvalidExperiments
    RAISERROR (@message, 10, 1)
    return 51221
  end

  ---------------------------------------------------
  -- Resolve researcher PRN
  ---------------------------------------------------

  declare @userID int
  execute @userID = GetUserID @researcher
  if @userID = 0
  begin
    -- Could not find entry in database for PRN @researcher
    -- Try to auto-resolve the name

    Declare @MatchCount int
    Declare @NewPRN varchar(64)

    exec AutoResolveNameToPRN @researcher, @MatchCount output, @NewPRN output, @userID output

    If @MatchCount = 1
    Begin
      -- Single match found; update @researcher
      Set @researcher = @NewPRN
    End
    Else
    Begin
     set @message = 'Could not find entry in database for researcher PRN "' + @researcher + '"'
     RAISERROR (@message, 10, 1)
     return 51037
    End

  end

  ---------------------------------------------------
  -- start transaction
  --
  declare @transName varchar(32)
  set @transName = 'AddUpdateExperimentGroup'
  begin transaction @transName
  
  ---------------------------------------------------
  -- action for add mode
  ---------------------------------------------------
  if @Mode = 'add'
  begin
 
    INSERT INTO T_Experiment_Groups (
      EG_Group_Type, 
      EG_Created, 
      EG_Description, 
      Parent_Exp_ID,
      Researcher,
      Tab
   ) VALUES (
      @GroupType, 
      getdate(), 
      @Description, 
      @ParentExpID,
      @Researcher,
      @Tab
   )
   --
   SELECT @myError = @@error, @myRowCount = @@rowcount
   --
   if @myError <> 0
   begin
     rollback transaction @transName
     set @message = 'Insert operation failed'
     RAISERROR (@message, 10, 1)
     return 51007
   end
    
   -- return IDof newly created entry
   --
   set @ID = IDENT_CURRENT('T_Experiment_Groups')

  end -- add mode

  ---------------------------------------------------
  -- action for update mode
  ---------------------------------------------------
  --
  if @Mode = 'update' 
  begin
    set @myError = 0
    --

    UPDATE T_Experiment_Groups 
    SET 
      EG_Group_Type = @GroupType, 
      EG_Description = @Description, 
      Parent_Exp_ID = @ParentExpID,
      Researcher = @Researcher,
      TAB = @Tab
    WHERE (Group_ID = @ID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      rollback transaction @transName
      set @message = 'Update operation failed: "' + @ID + '"'
      RAISERROR (@message, 10, 1)
      return 51004
    end
  end -- update mode

  ---------------------------------------------------
  -- update member experiments 
  ---------------------------------------------------
 
  if @Mode = 'add' OR @Mode = 'update' 
  begin
    -- remove any existing group members that are not in temporary table
    --
    DELETE FROM T_Experiment_Group_Members
    WHERE
      (Group_ID = @ID) AND 
      (Exp_ID NOT IN (SELECT Exp_ID FROM #XR))
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      rollback transaction @transName
      set @message = 'Failed trying to remove members from group'
      RAISERROR (@message, 10, 1)
  return 51004
    end
      
    -- add group members from temporary table that are not already members
    --
    INSERT INTO T_Experiment_Group_Members
      (Group_ID, Exp_ID)
    SELECT  @ID, #XR.Exp_ID
    FROM #XR
    WHERE #XR.Exp_ID NOT IN (SELECT Exp_ID FROM T_Experiment_Group_Members WHERE Group_ID = @ID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      rollback transaction @transName
      set @message = 'Failed trying to add members to group'
      RAISERROR (@message, 10, 1)
      return 51004
    end
  end

  commit transaction @transName
  /**/
  return @myError


GO
GRANT EXECUTE ON [dbo].[AddUpdateExperimentGroup] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateExperimentGroup] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateExperimentGroup] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateExperimentGroup] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateExperimentGroup] TO [PNL\D3M580] AS [dbo]
GO
