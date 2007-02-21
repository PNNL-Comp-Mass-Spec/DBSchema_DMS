/****** Object:  StoredProcedure [dbo].[AddUpdateAnalysisJobProcessors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE AddUpdateAnalysisJobProcessors
/****************************************************
**
**  Desc: Adds new or edits existing T_Analysis_Job_Processors
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 02/15/2007
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
  @ID int output,
  @State char(1),
  @ProcessorName varchar(64),
  @Machine varchar(64),
  @Notes varchar(512),
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
     FROM  T_Analysis_Job_Processors
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
 
  INSERT INTO T_Analysis_Job_Processors (
    ID, 
    State, 
    Processor_Name, 
    Machine, 
    Notes
  ) VALUES (
    @ID, 
    @State, 
    @ProcessorName, 
    @Machine, 
    @Notes
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
    set @ID = IDENT_CURRENT('T_Analysis_Job_Processors')

  end -- add mode

  ---------------------------------------------------
  -- action for update mode
  ---------------------------------------------------
  --
  if @Mode = 'update' 
  begin
    set @myError = 0
    --

    UPDATE T_Analysis_Job_Processors 
    SET 
      ID = @ID, 
      State = @State, 
      Processor_Name = @ProcessorName, 
      Machine = @Machine, 
      Notes = @Notes
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
