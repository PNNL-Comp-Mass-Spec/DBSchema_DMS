/****** Object:  StoredProcedure [dbo].[GetGlobalModMapID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE GetGlobalModMapID
/****************************************************
**
**	Desc: Gets GlobalModMapID for given set of param entry specs
**
**	Return values: 0: failure, otherwise, ParamFileID
**
**	Parameters: 
**
**		Auth: kja
**		Date: 08/09/2004
**    
*****************************************************/
(
		@ParamFileID int,
		@GlobalModID int,
		@LocalSymbolID int
)
As
	declare @GlobalModMapID int
	set @GlobalModMapID = 0
	
	
	SELECT @GlobalModMapID = RefNum FROM T_Peptide_Mod_Param_File_List
		WHERE ((Param_File_ID = @ParamFileID) AND (Mod_ID = @GlobalModID) 
			AND (Local_Symbol_ID = @LocalSymbolID))
		
	return(@GlobalModMapID)

GO
