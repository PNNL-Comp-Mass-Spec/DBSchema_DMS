/****** Object:  StoredProcedure [dbo].[GetParamFileModInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure GetParamFileModInfo
/****************************************************
** 
**	Desc:
**		For given analysis parameter file, look up
**		potential dynamic and actual static modifications 
**		and return description of them as set of strings 
**
**		Return values: 0: success, otherwise, error code
** 
**	Parameters:
**		  @parameterFileName	name of analysis parameter file
**
**	Updates: 
**		07/24/2004 grk - Initial version
**		07/26/2004 mem - Added Order By Mod_ID
**		08/07/2004 mem - Added @paramFileFound parameter and updated references to use T_Seq_Local_Symbols_List
**		08/20/2004 grk - Major change to support consolidated mod description
**		08/22/2004 grk - added @paramFileID
**		02/12/2010 mem - Increased size of @ParamFileName to varchar(255)
**    
*****************************************************/
(
	@parameterFileName varchar(255),
	@paramFileID int output,
	@paramFileFound tinyint=0 output,
	@PM_TargetSymbolList varchar(128) output,
	@PM_MassCorrectionTagList varchar(512) output,
	@NP_MassCorrectionTagList varchar(512) output,
	@message varchar(256) output
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	declare @ln int
	
	set @paramFileID = 0
	set @PM_TargetSymbolList = ''
	set @PM_MassCorrectionTagList = ''
	set @NP_MassCorrectionTagList  = ''

	-----------------------------------------------------------
	-- Make sure this parameter file is defined in T_Param_Files
	-----------------------------------------------------------
	--
	SELECT 
		@paramFileID =  Param_File_ID
	FROM T_Param_Files
	WHERE Param_File_Name = @parameterFileName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	
	if @paramFileID <> 0
		set @paramFileFound = 1
	else
	begin
		set @paramFileFound = 0
		set @message = 'Unknown parameter file name: ' + @parameterFileName
		goto done
	end
	
	-----------------------------------------------------------
	-- dynamic mods
	-----------------------------------------------------------
	--

	SELECT
		@PM_TargetSymbolList = @PM_TargetSymbolList + Local_Symbol + ',', 
		@PM_MassCorrectionTagList = @PM_MassCorrectionTagList + cast( Mass_Correction_Tag as varchar(12)) + ','
	FROM
		V_Param_File_Mass_Mod_Info
	WHERE     
		(Mod_Type_Symbol = 'D') AND 
		(Param_File_Name = @parameterFileName)
	GROUP BY Local_Symbol,  Mass_Correction_Tag
	ORDER BY Local_Symbol
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to get dynamic modifications'
		goto done
	end

	-- future: make sure that a local symbol only appears once

	-----------------------------------------------------------
	-- static mods and terminus mods
	-----------------------------------------------------------

	SELECT
		@PM_TargetSymbolList = @PM_TargetSymbolList + Residue_Symbol + ',', 
		@PM_MassCorrectionTagList = @PM_MassCorrectionTagList + cast( Mass_Correction_Tag as varchar(12)) + ','
	FROM
		V_Param_File_Mass_Mod_Info
	WHERE     
		(Mod_Type_Symbol in ('T', 'P', 'S') ) AND 
		(Param_File_Name = @parameterFileName)
	ORDER BY Residue_Symbol
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to get static and terminus modifications'
		goto done
	end


	-----------------------------------------------------------
	-- isotopic mods
	-----------------------------------------------------------

	SELECT
		@NP_MassCorrectionTagList = @NP_MassCorrectionTagList + cast( Mass_Correction_Tag as varchar(12)) + ','
	FROM
		V_Param_File_Mass_Mod_Info
	WHERE     
		(Mod_Type_Symbol = 'I' ) AND 
		(Param_File_Name = @parameterFileName)
	ORDER BY  Mass_Correction_Tag
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to get isotopic modifications'
		goto done
	end


	-----------------------------------------------------------
	-- Exit
	-----------------------------------------------------------
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[GetParamFileModInfo] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetParamFileModInfo] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetParamFileModInfo] TO [MTS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetParamFileModInfo] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetParamFileModInfo] TO [PNL\D3M580] AS [dbo]
GO
