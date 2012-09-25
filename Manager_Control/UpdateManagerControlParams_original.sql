/****** Object:  StoredProcedure [dbo].[UpdateManagerControlParams_original] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create Procedure [dbo].[UpdateManagerControlParams_original]
/****************************************************
**
**	Desc: 
**	Changes manager params for set of given managers
**  
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: jds
**		Date: 6/20/2007
**    
**    7/27/07 - JDS - Added support for parameters that 
**		do not exist for a manager
**    
*****************************************************/
	@mode varchar(32), 
	@param1 varchar(512),
	@param1Type varchar(50),
	@param2 varchar(512),
	@param2Type varchar(50),
	@param3 varchar(512),
	@param3Type varchar(50),
	@param4 varchar(512),
	@param4Type varchar(50),
	@param5 varchar(512),
	@param5Type varchar(50),
	@managerIDList varchar(2048)
As
declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	--

	declare @paramID int
	set @paramID = 0

	Create table #newManagerIDList(
		new_M_ID int
		)

	Create table #updateManagerIDList(
		upd_M_ID int
		)

	---------------------------------------------------
	-- Gather manager new list and update list
	---------------------------------------------------
	--Insert all manager IDs into new temp table
	Insert into #newManagerIDList
	SELECT * FROM MakeTableFromList(@managerIDList) 

	--Insert existing manager IDs into update table
	Insert into #updateManagerIDList
	Select MgrID
	from T_ParamType PT
			join T_ParamValue PV on PV.TypeID = PT.ParamID and PT.ParamName = @param1Type
	where MgrID in 
			(
			SELECT * FROM #newManagerIDList 
			)
			and MgrID in 
				(
				SELECT M_ID
				FROM T_ParamValue
					join T_ParamType ON dbo.T_ParamValue.TypeID = dbo.T_ParamType.ParamID
					join T_Mgrs on MgrID = M_ID
				WHERE ParamName = 'controlfromwebsite' AND Value = 'True' 
				)

	--Remove updated manager IDs from the new temp table
	Delete From #newManagerIDList
	Where new_M_ID in ( SELECT * FROM #updateManagerIDList )
 
	--Retrieve the parameter ID from the parameter Type table
	select @paramID = ParamID
	from T_ParamType
	where ParamName = @param1Type

	--Add new parameters and values to managers that don't yet have a value
	Insert into T_ParamValue(TypeID, Value, MgrID)
	Select @paramID, @param1, new_M_ID
	FROM #newManagerIDList

	---------------------------------------------------
	-- Update first parameter of all Managers in list
	---------------------------------------------------
	update T_ParamValue
	set [Value] = @param1
	from T_ParamType PT
	where PT.ParamID = @paramID
			and MgrID in 
			( 
			SELECT * FROM #updateManagerIDList
			)
			and MgrID in 
			( 
			SELECT M_ID
			FROM T_ParamValue
				join T_ParamType ON dbo.T_ParamValue.TypeID = dbo.T_ParamType.ParamID
				join T_Mgrs on MgrID = M_ID
			WHERE ParamName = 'controlfromwebsite' AND Value = 'True' 
			)

	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount				
	--
	if @myError <> 0
	begin
		RAISERROR ('Error trying to update First Manager param', 10, 1)
		return 51310
	end

	---------------------------------------------------
	-- Gather manager new list and update list for Param 2
	---------------------------------------------------
	Truncate table #newManagerIDList
	Truncate table #updateManagerIDList

	--Insert all manager IDs into new temp table
	Insert into #newManagerIDList
	SELECT * FROM MakeTableFromList(@managerIDList) 

	--Insert existing manager IDs into update table
	Insert into #updateManagerIDList
	Select MgrID
	from T_ParamType PT
			join T_ParamValue PV on PV.TypeID = PT.ParamID and PT.ParamName = @param2Type
	where MgrID in 
			(
			SELECT * FROM #newManagerIDList 
			)
			and MgrID in 
				(
				SELECT M_ID
				FROM T_ParamValue
					join T_ParamType ON dbo.T_ParamValue.TypeID = dbo.T_ParamType.ParamID
					join T_Mgrs on MgrID = M_ID
				WHERE ParamName = 'controlfromwebsite' AND Value = 'True' 
				)

	--Remove updated manager IDs from the new temp table
	Delete From #newManagerIDList
	Where new_M_ID in ( SELECT * FROM #updateManagerIDList )
 
	--Retrieve the parameter ID from the parameter Type table
	select @paramID = ParamID
	from T_ParamType
	where ParamName = @param2Type

	--Add new parameters and values to managers that don't yet have a value
	Insert into T_ParamValue(TypeID, Value, MgrID)
	Select @paramID, @param2, new_M_ID
	FROM #newManagerIDList

	---------------------------------------------------
	-- Update second parameter of all Managers in list
	---------------------------------------------------
	update T_ParamValue
	set [Value] = @param2
	from T_ParamType PT
		join T_ParamValue PV on PV.TypeID = PT.ParamID and PT.ParamName = @param2Type
	where MgrID in 
			( 
			SELECT * FROM #updateManagerIDList 
			)
			and MgrID in 
				( 
				SELECT M_ID
				FROM T_ParamValue
					join T_ParamType ON dbo.T_ParamValue.TypeID = dbo.T_ParamType.ParamID
					join T_Mgrs on MgrID = M_ID
				WHERE ParamName = 'controlfromwebsite' AND Value = 'True' 
				)
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount				
	--
	if @myError <> 0
	begin
		RAISERROR ('Error trying to update Second Manager param', 10, 1)
		return 51310
	end

	---------------------------------------------------
	-- Gather manager new list and update list for Param 3
	---------------------------------------------------
	Truncate table #newManagerIDList
	Truncate table #updateManagerIDList

	--Insert all manager IDs into new temp table
	Insert into #newManagerIDList
	SELECT * FROM MakeTableFromList(@managerIDList) 

	--Insert existing manager IDs into update table
	Insert into #updateManagerIDList
	Select MgrID
	from T_ParamType PT
			join T_ParamValue PV on PV.TypeID = PT.ParamID and PT.ParamName = @param3Type
	where MgrID in 
			(
			SELECT * FROM #newManagerIDList 
			)
			and MgrID in 
				(
				SELECT M_ID
				FROM T_ParamValue
					join T_ParamType ON dbo.T_ParamValue.TypeID = dbo.T_ParamType.ParamID
					join T_Mgrs on MgrID = M_ID
				WHERE ParamName = 'controlfromwebsite' AND Value = 'True' 
				)

	--Remove updated manager IDs from the new temp table
	Delete From #newManagerIDList
	Where new_M_ID in ( SELECT * FROM #updateManagerIDList )
 
	--Retrieve the parameter ID from the parameter Type table
	select @paramID = ParamID
	from T_ParamType
	where ParamName = @param3Type

	--Add new parameters and values to managers that don't yet have a value
	Insert into T_ParamValue(TypeID, Value, MgrID)
	Select @paramID, @param3, new_M_ID
	FROM #newManagerIDList

	---------------------------------------------------
	-- Update third parameter of all Managers in list
	---------------------------------------------------
	update T_ParamValue
	set [Value] = @param3
	from T_ParamType PT
		join T_ParamValue PV on PV.TypeID = PT.ParamID and PT.ParamName = @param3Type
	where MgrID in 
			(
			SELECT * FROM #updateManagerIDList
			)
			and MgrID in 
				( 
				SELECT M_ID
				FROM T_ParamValue
					join T_ParamType ON dbo.T_ParamValue.TypeID = dbo.T_ParamType.ParamID
					join T_Mgrs on MgrID = M_ID
				WHERE ParamName = 'controlfromwebsite' AND Value = 'True' 
				)
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount				
	--
	if @myError <> 0
	begin
		RAISERROR ('Error trying to update Third Manager param', 10, 1)
		return 51310
	end

	---------------------------------------------------
	-- Gather manager new list and update list for Param 4
	---------------------------------------------------
	Truncate table #newManagerIDList
	Truncate table #updateManagerIDList

	--Insert all manager IDs into new temp table
	Insert into #newManagerIDList
	SELECT * FROM MakeTableFromList(@managerIDList) 

	--Insert existing manager IDs into update table
	Insert into #updateManagerIDList
	Select MgrID
	from T_ParamType PT
			join T_ParamValue PV on PV.TypeID = PT.ParamID and PT.ParamName = @param4Type
	where MgrID in 
			(
			SELECT * FROM #newManagerIDList 
			)
			and MgrID in 
				(
				SELECT M_ID
				FROM T_ParamValue
					join T_ParamType ON dbo.T_ParamValue.TypeID = dbo.T_ParamType.ParamID
					join T_Mgrs on MgrID = M_ID
				WHERE ParamName = 'controlfromwebsite' AND Value = 'True' 
				)

	--Remove updated manager IDs from the new temp table
	Delete From #newManagerIDList
	Where new_M_ID in ( SELECT * FROM #updateManagerIDList )
 
	--Retrieve the parameter ID from the parameter Type table
	select @paramID = ParamID
	from T_ParamType
	where ParamName = @param4Type

	--Add new parameters and values to managers that don't yet have a value
	Insert into T_ParamValue(TypeID, Value, MgrID)
	Select @paramID, @param4, new_M_ID
	FROM #newManagerIDList

	---------------------------------------------------
	-- Update fourth parameter of all Managers in list
	---------------------------------------------------
	update T_ParamValue
	set [Value] = @param4
	from T_ParamType PT
		join T_ParamValue PV on PV.TypeID = PT.ParamID and PT.ParamName = @param4Type
	where MgrID in 
			(
			SELECT * FROM #updateManagerIDList
			)
			and MgrID in 
				( 
				SELECT M_ID
				FROM T_ParamValue
					join T_ParamType ON dbo.T_ParamValue.TypeID = dbo.T_ParamType.ParamID
					join T_Mgrs on MgrID = M_ID
				WHERE ParamName = 'controlfromwebsite' AND Value = 'True' 
				)
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount				
	--
	if @myError <> 0
	begin
		RAISERROR ('Error trying to update Fourth Manager param', 10, 1)
		return 51310
	end

	---------------------------------------------------
	-- Gather manager new list and update list for Param 5
	---------------------------------------------------
	Truncate table #newManagerIDList
	Truncate table #updateManagerIDList

	--Insert all manager IDs into new temp table
	Insert into #newManagerIDList
	SELECT * FROM MakeTableFromList(@managerIDList) 

	--Insert existing manager IDs into update table
	Insert into #updateManagerIDList
	Select MgrID
	from T_ParamType PT
			join T_ParamValue PV on PV.TypeID = PT.ParamID and PT.ParamName = @param5Type
	where MgrID in 
			(
			SELECT * FROM #newManagerIDList 
			)
			and MgrID in
				(
				SELECT M_ID
				FROM T_ParamValue
					join T_ParamType ON dbo.T_ParamValue.TypeID = dbo.T_ParamType.ParamID
					join T_Mgrs on MgrID = M_ID
				WHERE ParamName = 'controlfromwebsite' AND Value = 'True' 
				)

	--Remove updated manager IDs from the new temp table
	Delete From #newManagerIDList
	Where new_M_ID in ( SELECT * FROM #updateManagerIDList )
 
	--Retrieve the parameter ID from the parameter Type table
	select @paramID = ParamID
	from T_ParamType
	where ParamName = @param5Type

	--Add new parameters and values to managers that don't yet have a value
	Insert into T_ParamValue(TypeID, Value, MgrID)
	Select @paramID, @param5, new_M_ID
	FROM #newManagerIDList

	---------------------------------------------------
	-- Update fifth parameter of all Managers in list
	---------------------------------------------------
	update T_ParamValue
	set [Value] = @param5
	from T_ParamType PT
		join T_ParamValue PV on PV.TypeID = PT.ParamID and PT.ParamName = @param5Type
	where MgrID in 
			(
			SELECT * FROM #updateManagerIDList
			)
			and MgrID in 
				( 
				SELECT M_ID
				FROM T_ParamValue
					join T_ParamType ON dbo.T_ParamValue.TypeID = dbo.T_ParamType.ParamID
					join T_Mgrs on MgrID = M_ID
				WHERE ParamName = 'controlfromwebsite' AND Value = 'True' 
				)
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount				
	--
	if @myError <> 0
	begin
		RAISERROR ('Error trying to update Fifth Manager param', 10, 1)
		return 51310
	end


	return @myError

GO
