/****** Object:  StoredProcedure [dbo].[AddExperimentReferenceCompound] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[AddExperimentReferenceCompound]
/****************************************************
**
**	Desc: Adds reference compound entries to DB for given experiment
**
**	The calling procedure must create and populate temporary table #Tmp_ExpToRefCompoundMap:
**
**		CREATE TABLE #Tmp_ExpToRefCompoundMap (
**			Compound_Name varchar(128) not null,
**			Compound_ID int null
**		)
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	11/29/2017 mem - Initial version
**    
*****************************************************/
(
	@expID int,
	@updateCachedInfo tinyint = 1,
	@message varchar(255) = '' output
)
As		
	Declare @myError int = 0
	Declare @myRowCount int = 0

	Declare @msg varchar(256)
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	If @expID Is Null
	Begin	
		set @message = 'Experiment ID cannot be null'
		return 51061
	End
	
	Set @updateCachedInfo = IsNull(@updateCachedInfo, 1)
	Set @message = ''
	
	---------------------------------------------------
	-- Try to resolve any null reference compound ID values in #Tmp_ExpToRefCompoundMap
	---------------------------------------------------
	--
	UPDATE #Tmp_ExpToRefCompoundMap
	SET Compound_ID = Src.Compound_ID
	FROM #Tmp_ExpToRefCompoundMap Target
	     INNER JOIN T_Reference_Compound Src
	       ON Src.Compound_Name = Target.Compound_Name
	WHERE Target.Compound_ID Is Null
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	---------------------------------------------------
	-- Look for invalid entries in #Tmp_ExpToRefCompoundMap
	---------------------------------------------------
	--
	Declare @invalidCompoundList varchar(512) = null

	SELECT @invalidCompoundList = Coalesce(@invalidCompoundList + ', ' + Compound_Name, Compound_Name)
	FROM #Tmp_ExpToRefCompoundMap
	WHERE Compound_ID IS NULL
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If Len(IsNull(@invalidCompoundList, '')) > 0
	Begin
		Set @message = 'Invalid reference compound name(s): ' + @invalidCompoundList
		return 51063
	End
		
	---------------------------------------------------
	-- Add/remove reference compounds
	---------------------------------------------------
	--
	DELETE T_Experiment_Reference_Compounds
	WHERE Exp_ID = @expID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	INSERT INTO T_Experiment_Reference_Compounds (Exp_ID, Compound_ID)
	SELECT DISTINCT @expID as Exp_ID, Compound_ID
	FROM #Tmp_ExpToRefCompoundMap
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error updating reference compound mapping for experiment ' + Cast(@expID as varchar(9))
		return 51062
	end
	
	---------------------------------------------------
	-- Optionally update T_Cached_Experiment_Components
	---------------------------------------------------
	--
	If @updateCachedInfo > 0
	Begin
		Exec UpdateCachedExperimentComponentNames @expID
	End
	
	return 0

GO
