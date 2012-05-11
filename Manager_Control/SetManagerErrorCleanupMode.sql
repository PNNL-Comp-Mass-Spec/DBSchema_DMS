/****** Object:  StoredProcedure [dbo].[SetManagerErrorCleanupMode] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SetManagerErrorCleanupMode
/****************************************************
**
**	Desc: 
**		Sets ManagerErrorCleanupMode to @CleanupMode for the given list of managers
**		If @ManagerList is blank, then sets it to @CleanupMode for all "Analysis Tool Manager" managers
**
**	Auth:	mem
**	Date:	09/10/2009 mem - Initial version
**
*****************************************************/
(
	@ManagerList varchar(4000) = '',
	@CleanupMode tinyint = 1,				-- 0 = No auto cleanup, 1 = Attempt auto cleanup once, 2 = Auto cleanup always
	@message varchar(512) = '' output
)
AS
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	Declare @mgrID int	
	Declare @ParamID int
	Declare @CleanupModeString varchar(12)
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	
	Set @ManagerList = IsNull(@ManagerList, '')
	Set @CleanupMode = IsNull(@CleanupMode, 1)
	Set @message = ''
	
	If @CleanupMode < 0
		Set @CleanupMode = 0
	
	If @CleanupMode > 2
		Set @CleanupMode = 2
		
	CREATE TABLE #TmpManagerList (
		ManagerName varchar(128) NOT NULL,
		MgrID int NULL
	)

	---------------------------------------------------
	-- Confirm that the manager name is valid
	---------------------------------------------------

	Set @ManagerList = IsNull(@ManagerList, '')
	
	If Len(@ManagerList) > 0
		INSERT INTO #TmpManagerList (ManagerName)
		SELECT Value
		FROM dbo.udfParseDelimitedList(@ManagerList, ',')
		WHERE Len(IsNull(Value, '')) > 0
	Else
		INSERT INTO #TmpManagerList (ManagerName)
		SELECT M_Name
		FROM T_Mgrs
		WHERE (M_TypeID = 11)

	UPDATE #TmpManagerList
	SET MgrID = T_Mgrs.M_ID
	FROM #TmpManagerList INNER JOIN T_Mgrs
	        ON T_Mgrs.M_Name = #TmpManagerList.ManagerName 
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount


	DELETE FROM #TmpManagerList
	WHERE MgrID IS NULL
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount <> 0
	Begin
		Set @message = 'Removed ' + Convert(varchar(12), @myRowCount) + ' invalid manager'
		If @myRowCount > 1
			Set @message = @message + 's'
		
		Set @message = @message + ' from #TmpManagerList'
		Print @message
	End
	
	---------------------------------------------------
	-- Lookup the ParamID value for 'ManagerErrorCleanupMode'
	---------------------------------------------------
	
	Set @ParamID = 0
	--
	SELECT @ParamID = ParamID
	FROM T_ParamType
	WHERE (ParamName = 'ManagerErrorCleanupMode')

	---------------------------------------------------
	-- Make sure each manager in #TmpManagerList has an entry 
	--  in T_ParamValue for 'ManagerErrorCleanupMode' 
	---------------------------------------------------

	INSERT INTO T_ParamValue (MgrID, TypeID, Value) 
	SELECT A.MgrID, @ParamID, '0'
	FROM ( SELECT MgrID
	       FROM #TmpManagerList
	     ) A
	     LEFT OUTER JOIN
	      ( SELECT #TmpManagerList.MgrID
	        FROM #TmpManagerList
	             INNER JOIN T_ParamValue
	               ON #TmpManagerList.MgrID = T_ParamValue.MgrID	                            
	        WHERE T_ParamValue.TypeID = @ParamID 
	     ) B 
	       ON A.MgrID = B.MgrID
	WHERE B.MgrID IS NULL
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount <> 0
	Begin
		Set @message = 'Added entry for "ManagerErrorCleanupMode" to T_ParamValue for ' + Convert(varchar(12), @myRowCount) + ' manager'
		If @myRowCount > 1
			Set @message = @message + 's'
			
		Print @message
	End

	---------------------------------------------------
	-- Update the 'ManagerErrorCleanupMode' entry for each manager in #TmpManagerList
	---------------------------------------------------

	Set @CleanupModeString = Convert(varchar(12), @CleanupMode)
	
	UPDATE T_ParamValue
	SET Value = @CleanupModeString
	FROM T_ParamValue
	     INNER JOIN #TmpManagerList
	       ON T_ParamValue.MgrID = #TmpManagerList.MgrID
	WHERE (T_ParamValue.TypeID = @ParamID) AND
	      T_ParamValue.Value <> 'True'
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount <> 0
	Begin
		Set @message = 'Set "ManagerErrorCleanupMode" to ' + @CleanupModeString + ' for ' + Convert(varchar(12), @myRowCount) + ' manager'
		If @myRowCount > 1
			Set @message = @message + 's'
			
		Print @message
	End

	---------------------------------------------------
	-- Exit the procedure
	---------------------------------------------------
Done:
	return @myError
	
GO
GRANT EXECUTE ON [dbo].[SetManagerErrorCleanupMode] TO [mtuser] AS [dbo]
GO
