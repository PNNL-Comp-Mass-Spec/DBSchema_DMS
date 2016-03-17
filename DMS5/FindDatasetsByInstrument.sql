/****** Object:  StoredProcedure [dbo].[FindDatasetsByInstrument] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.FindDatasetsByInstrument
/****************************************************
**
**	Desc: 
**		Returns result set of most recent N Datasets
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	08/14/2007
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@numberOfDatasets varchar(20) = '5',
	@instOpsRoles varchar(128),
	@Created_After varchar(32),
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''
	
	---------------------------------------------------
	-- get cutoff date
	---------------------------------------------------
	declare @iCreated_after datetime
	--
	if @Created_After <> ''
		SET @iCreated_after = CONVERT(datetime, @Created_After)
	else
		SET @iCreated_after = DATEADD (day, -14, getdate()) 

	---------------------------------------------------
	-- get list of active instruments
	---------------------------------------------------
	--
	DECLARE @inst TABLE 
	( 
		id INT,
		opsRole varchar(50)
	)
	INSERT INTO @inst
	(id, opsRole)
	SELECT     Instrument_ID, IN_operations_role
	FROM         T_Instrument_Name
	WHERE     (IN_status = 'active')	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to get list of active instruments'
		RAISERROR (@message, 10, 1)
		return 51001
	end

	---------------------------------------------------
	-- restrict list of instruments by role
	---------------------------------------------------
	
	if @instOpsRoles <> ''
	begin
		DELETE FROM @inst
		WHERE NOT opsRole IN (
			SELECT Item FROM dbo.MakeTableFromList(@instOpsRoles)
		)
	end

	---------------------------------------------------
	-- most recent datasets for each instrument
	--
	DECLARE @dst TABLE 
	( 
		id int,
		inst int,
		seq int NULL
	)

	---------------------------------------------------
	-- loop through the instruments and get
	-- most recent 20 datasets for each one
	-- and give each dataset a unique sequence value
	---------------------------------------------------
	--
	declare @instID int
	set @instID = 0
	declare @done int
	set @done = 0
	declare @seq int
	--
	while @done = 0
	begin
		---------------------------------------------------
		-- get next instrument ID
		--
		SELECT TOP 1 @instID = id
		FROM @inst
		WHERE id > @instID
		ORDER BY id ASC
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error stepping through list of active instruments'
			RAISERROR (@message, 10, 1)
			return 51002
		end
	
		---------------------------------------------------
		-- get the most recent 20 datasets for the instrument
		--
		if @myRowCount = 0
		begin
			set @done = 1
		end
		else
		begin
			INSERT INTO @dst (id, inst)
			SELECT TOP 20 
				Dataset_ID, @instID
			FROM T_Dataset
			WHERE 
				DS_instrument_name_ID = @instID AND
				DS_Last_Affected > @iCreated_after
			ORDER BY DS_created DESC
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error getting datasets for given instrument'
				RAISERROR (@message, 10, 1)
				return 51003
			end
			
			---------------------------------------------------
			-- give each dataset a unique sequence number
			--
			set @seq = 0
			--
			UPDATE @dst
			SET @seq = seq = (@seq + 1)
			WHERE inst = @instID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error setting sequence for datasets'
				RAISERROR (@message, 10, 1)
				return 51004
			end

		end
	end

	---------------------------------------------------
	-- output dataset information using unique sequence
	-- numbers as cutoff to limit datasets per instrument
	---------------------------------------------------
	--
	declare @ndst int
	if @numberOfDatasets = ''
		set @ndst = 5
	else
		set @ndst = cast(@numberOfDatasets as int)
	--
	SELECT 
	  *
	FROM   
	  V_Dataset_Report AS V
	  INNER JOIN @dst AS T
		ON T.id = V.ID
	WHERE  T.seq <= @ndst

	return @myError

GO
GRANT EXECUTE ON [dbo].[FindDatasetsByInstrument] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[FindDatasetsByInstrument] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[FindDatasetsByInstrument] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[FindDatasetsByInstrument] TO [PNL\D3M580] AS [dbo]
GO
