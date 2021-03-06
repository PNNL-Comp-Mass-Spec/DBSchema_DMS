/****** Object:  StoredProcedure [dbo].[MakeAutomaticRequestedRunFactors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE MakeAutomaticRequestedRunFactors
/****************************************************
**
**	Desc: 
**	Create reqeusted run factors from metadata values
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	03/23/2010 grk - initial release
**			11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**			11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**    
*****************************************************/
(
	@batchID INT,
	@mode VARCHAR(32) = 'all', -- 'all', 'actual_run_order'
	@message varchar(512) OUTPUT,
	@callingUser varchar(128) = ''
)
As
	SET NOCOUNT ON 

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	SET @message = ''

	--
	DECLARE @factorList VARCHAR(MAX)
	SET @factorList = ''

	-----------------------------------------------------------
	-- make factor list for actual run order
	-- FUTURE: mode = 'actual_run_order' or 'all'
	-----------------------------------------------------------
	--
	CREATE TABLE #REQ (
		Request INT,
		Seq INT IDENTITY(1,1) NOT NULL
	)
	--
	-----------------------------------------------------------
	-- 
	INSERT INTO #REQ
		( Request )
	SELECT
	  T_Requested_Run.ID
	FROM
	  T_Requested_Run
	  INNER JOIN T_Dataset ON T_Requested_Run.DatasetID = T_Dataset.Dataset_ID
	WHERE
	  ( T_Requested_Run.RDS_BatchID = @batchID )
	  AND ( NOT ( T_Dataset.Acq_Time_Start IS NULL )
		  )
	ORDER BY
	  T_Dataset.Acq_Time_Start
	--
	-----------------------------------------------------------
	--
	 SELECT 
		@factorList = @factorList +
		'<r ' + 
		'i="' + CONVERT(VARCHAR(12), Request) + '" ' + 
		'f="Actual_Run_Order" ' +
		'v="' + CONVERT(VARCHAR(12), Seq) + '" ' +
		'/>' 
	FROM #REQ
	

	-----------------------------------------------------------
	-- update factors
	-----------------------------------------------------------
	--
	IF @factorList = ''
		RETURN @myError
	--
	IF @callingUser = ''
	BEGIN 
		SET @callingUser = dbo.GetUserLoginWithoutDomain('')
	END
	--
	EXEC @myError = UpdateRequestedRunFactors
							@factorList,
							@message OUTPUT,
							@callingUser
							
	RETURN @myError
GO
GRANT VIEW DEFINITION ON [dbo].[MakeAutomaticRequestedRunFactors] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[MakeAutomaticRequestedRunFactors] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MakeAutomaticRequestedRunFactors] TO [Limited_Table_Write] AS [dbo]
GO
