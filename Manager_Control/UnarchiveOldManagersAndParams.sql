/****** Object:  StoredProcedure [dbo].[UnarchiveOldManagersAndParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UnarchiveOldManagersAndParams
/****************************************************
** 
**	Desc:	Moves managers from T_OldManagers to T_Mgrs
**			and moves manager parameters from T_ParamValue_OldManagers to T_ParamValue
**
**			To reverse this process, use procedure UnarchiveOldManagersAndParams
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	02/25/2016 mem - Initial version
**    
*****************************************************/
(
	@MgrList varchar(max),	-- One or more manager names (comma-separated list); supports wildcards because uses stored procedure ParseManagerNameList
	@InfoOnly tinyint = 1,
	@EnableControlFromWebsite tinyint = 0,
	@message varchar(512)='' output
)
As
	Set XACT_ABORT, NoCount On
	
	declare @myRowCount int
	declare @myError int
	set @myRowCount = 0
	set @myError = 0
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	--
	Set @MgrList = IsNull(@MgrList, '')
	Set @InfoOnly = IsNull(@InfoOnly, 1)
	Set @EnableControlFromWebsite = IsNull(@EnableControlFromWebsite, 1)
	Set @message = ''

	If @EnableControlFromWebsite > 0
		Set @EnableControlFromWebsite= 1
		
	CREATE TABLE #TmpManagerList (		
		Manager_Name varchar(50) NOT NULL,
		M_ID int NULL
	)
	
	---------------------------------------------------
	-- Populate #TmpManagerList with the managers in @MgrList
	---------------------------------------------------
	--
	
	exec ParseManagerNameList @MgrList, @RemoveUnknownManagers=0

	If Not Exists (Select * from #TmpManagerList)
	Begin
		Set @message = '@MgrList was empty'
		Select @Message as Warning
		Goto done		
	End

	---------------------------------------------------
	-- Validate the manager names
	---------------------------------------------------
	--
	UPDATE #TmpManagerList
	SET M_ID = M.M_ID
	FROM #TmpManagerList Target
	     INNER JOIN T_OldManagers M
	       ON Target.Manager_Name = M.M_Name
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If Exists (Select * from #TmpManagerList where M_ID Is Null)
	Begin
		SELECT 'Unknown manager (not in T_OldManagers)' AS Warning, Manager_Name
		FROM #TmpManagerList
		WHERE M_ID  Is Null
		ORDER BY Manager_Name			
	End

	If Exists (Select * From #TmpManagerList Where Manager_Name Like '%Params%')
	Begin
		SELECT 'Will not process managers with "Params" in the name (for safety)' AS Warning,
		       Manager_Name
		FROM #TmpManagerList
		WHERE Manager_Name Like '%Params%'
		ORDER BY Manager_Name
		--
		DELETE From #TmpManagerList Where Manager_Name Like '%Params%'
	End

	If Exists (Select * FROM #TmpManagerList Where Manager_Name IN (Select M_Name From T_Mgrs))
	Begin
		SELECT DISTINCT 'Will not process managers with existing entries in T_Mgrs' AS Warning,
		                Manager_Name
		FROM #TmpManagerList Src
		WHERE Manager_Name IN (Select M_Name From T_Mgrs)
		ORDER BY Manager_Name
		--
		DELETE From #TmpManagerList Where Manager_Name IN (Select M_Name From T_Mgrs)
	End

	If Exists (Select * FROM #TmpManagerList Where M_ID IN (Select Distinct MgrID From T_ParamValue))
	Begin
		SELECT DISTINCT 'Will not process managers with existing entries in T_ParamValue' AS Warning,
		                Manager_Name
		FROM #TmpManagerList Src
		WHERE M_ID IN (Select Distinct MgrID From T_ParamValue)
		ORDER BY Manager_Name
		--
		DELETE From #TmpManagerList Where M_ID IN (Select Distinct MgrID From T_ParamValue)
	End

	If @InfoOnly <> 0
	Begin
		SELECT Src.Manager_Name,
		       @EnableControlFromWebsite AS M_ControlFromWebsite,
		       PV.M_TypeID,
		       PV.ParamName,
		       PV.Entry_ID,
		       PV.TypeID,
		       PV.[Value],
		       PV.MgrID,
		       PV.[Comment],
		       PV.Last_Affected,
		       PV.Entered_By
		FROM #TmpManagerList Src
		     LEFT OUTER JOIN V_OldParamValue PV
		       ON PV.MgrID = Src.M_ID
		ORDER BY Src.Manager_Name, ParamName

	End
	Else
	Begin
		DELETE FROM #TmpManagerList WHERE M_ID is Null
		
		Declare @MoveParams varchar(24) = 'Move params transaction'
		Begin Tran @MoveParams
				
		SET IDENTITY_INSERT T_Mgrs ON		
		
		INSERT INTO T_Mgrs ( M_ID,
		                     M_Name,
		                     M_TypeID,
		                     M_ParmValueChanged,
		                     M_ControlFromWebsite )
		SELECT M.M_ID,
		       M.M_Name,
		       M.M_TypeID,
		       M.M_ParmValueChanged,
		       @EnableControlFromWebsite
		FROM T_OldManagers M
		     INNER JOIN #TmpManagerList Src
		       ON M.M_ID = Src.M_ID
		  LEFT OUTER JOIN T_Mgrs Target
		   ON Src.M_ID = Target.M_ID
		WHERE Target.M_ID IS NULL
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		SET IDENTITY_INSERT T_Mgrs Off
		--
		If @myError <> 0
		Begin
			Rollback
			Select 'Aborted (rollback) due to insert error for T_Mgrs' as Warning, @myError as ErrorCode
			Goto Done
		End			
		
		SET IDENTITY_INSERT T_ParamValue On
		
		INSERT INTO T_ParamValue (
		         Entry_ID,
		         TypeID,
		         [Value],
		         MgrID,
		         [Comment],
		         Last_Affected,
		         Entered_By )
		SELECT PV.Entry_ID,
		       PV.TypeID,
		       PV.[Value],
		       PV.MgrID,
		       PV.[Comment],
		       PV.Last_Affected,
		       PV.Entered_By
		FROM T_ParamValue_OldManagers PV
		     INNER JOIN #TmpManagerList Src
		       ON PV.MgrID = Src.M_ID
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		SET IDENTITY_INSERT T_ParamValue On
		--
		If @myError <> 0
		Begin
			Rollback
			Select 'Aborted (rollback) due to insert error for T_ParamValue_OldManagers' as Warning, @myError as ErrorCode
			Goto Done
		End
				
		DELETE T_ParamValue_OldManagers
		FROM T_ParamValue_OldManagers PV
		     INNER JOIN #TmpManagerList Src
		       ON PV.MgrID = Src.M_ID			

		DELETE T_OldManagers
		FROM T_OldManagers M
		     INNER JOIN #TmpManagerList Src
		       ON M.M_ID = Src.M_ID
		       		
		Commit Tran @MoveParams
	
		SELECT 'Moved to T_Managers and T_ParamValue' as Message,
		       Src.Manager_Name,
		       @EnableControlFromWebsite AS M_ControlFromWebsite,
		       PT.ParamName,
		       PV.Entry_ID,
		       PV.TypeID,
		       PV.[Value],
		       PV.MgrID,
		       PV.[Comment],
		       PV.Last_Affected,
		       PV.Entered_By
		FROM #TmpManagerList Src
		     LEFT OUTER JOIN T_ParamValue PV
		       ON PV.MgrID = Src.M_ID
		     LEFT OUTER JOIN T_ParamType PT ON
		     PV.TypeID = PT.ParamID
		ORDER BY Src.Manager_Name, ParamName
	End

	       
Done:
	RETURN @myError

GO
