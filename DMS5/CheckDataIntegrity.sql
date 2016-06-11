/****** Object:  StoredProcedure [dbo].[CheckDataIntegrity] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.CheckDataIntegrity
/****************************************************
**
**	Desc: 
**		Run miscellaneous data integrity checks
**		Intended to be run daily with @logErrors = 1
**
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	mem
**			06/10/2016 mem - Initial Version
**    
*****************************************************/
(
	@logErrors tinyint = 1,
    @message varchar(512) = '' output
)
AS
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @errMsg varchar(255)

	----------------------------------------------------------
	-- Validate the inputs
	----------------------------------------------------------
	
	Set @logErrors = IsNull(@logErrors, 1)
	Set @message = ''

	----------------------------------------------------------
	-- Look for datasets that map to multiple requested runs
	----------------------------------------------------------	

	Declare @datasetCount int
	Declare @firstDatasetID int

	SELECT @datasetCount = Count(*),
	       @firstDatasetID = Min(FilterQ.DatasetID)
	FROM ( SELECT DatasetID
	       FROM T_Requested_Run
	       WHERE NOT DatasetID IS NULL
	       GROUP BY DatasetID
	       HAVING Count(*) > 1 ) FilterQ

	If @datasetCount > 0
	Begin

		If @datasetCount = 1
			Set @errMsg = 'Dataset ' + Cast(@firstDatasetID AS varchar(12)) + ' is associated with multiple entries in T_Requested_Run'
		Else
			Set @errMsg = Cast(@datasetCount AS varchar(12)) + ' datasets map to multiple entries in T_Requested_Run; for example ' + Cast(@firstDatasetID AS varchar(12))

		if @logErrors = 0
		Begin
			SELECT @errMsg as Error_Message
		End
		Else
		Begin
			Exec PostLogEntry 'Error', @errMsg, 'CheckDataIntegrity'
			Print @errMsg
		End
		
		set @message = dbo.AppendToText(@message, @errMsg, 0, '; ')
	End	
	
 	---------------------------------------------------
	-- Done
 	---------------------------------------------------

Done:
	Return @myError

GO
