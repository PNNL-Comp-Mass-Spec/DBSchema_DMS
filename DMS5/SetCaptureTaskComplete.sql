/****** Object:  StoredProcedure [dbo].[SetCaptureTaskComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure SetCaptureTaskComplete
/****************************************************
**
**	Desc: Sets state of dataset record given by @datasetNum
**        according to given completion code and 
**        adjusts related database entries accordingly.
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 11/4/2002
**            8/6/2003 grk -- added handling for "Not Ready" state
**            11/13/2003 dac -- changed "FTICR" instrument class to "Finnigan_FTICR" following instrument class renaming
**            06/21/2005 grk -- added handling "requires_preparation" 
**    
*****************************************************/
(
	@datasetNum varchar(128),
	@completionCode int = 0, -- @completionCode = 0 -> success, @completionCode = 1 -> failure, @completionCode = 2 -> not ready	
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @datasetID int
	declare @datasetState int
	declare @completionState int
 	declare @result int
	declare @instrumentClass varchar(32)
	declare @doPrep tinyint
		
   	---------------------------------------------------
	-- resolve dataset into instrument class
	---------------------------------------------------
	--
	SELECT 
		@datasetID = T_Dataset.Dataset_ID, 
		@instrumentClass = T_Instrument_Name.IN_class,
		@doPrep = T_Instrument_Class.requires_preparation
	FROM   T_Dataset INNER JOIN
		T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN
        T_Instrument_Class ON T_Instrument_Name.IN_class = T_Instrument_Class.IN_class
	WHERE     (Dataset_Num = @datasetNum)	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Could not get dataset ID for dataset ' + @datasetNum
		goto done
	end

   	---------------------------------------------------
	-- choose completion state
	---------------------------------------------------
	
	if @completionCode = 0
		begin
			if @doPrep > 0
				set @completionState = 6 -- received
			else
				set @completionState = 3 -- normal completion
		end	
	else if @completionCode = 1
		begin
			set @completionState = 5 -- capture failed
		end
	else if @completionCode = 2
		begin
			set @completionState = 9 -- dataset not ready
		end
	

   	---------------------------------------------------
	-- perform the actions necessary when dataset is complete
	---------------------------------------------------
	--
	execute @result = DoDatasetCompletionActions @datasetNum, @completionState, @message output

   	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	if @message <> '' 
	begin
		RAISERROR (@message, 10, 1)
	end
	return @myError

GO
