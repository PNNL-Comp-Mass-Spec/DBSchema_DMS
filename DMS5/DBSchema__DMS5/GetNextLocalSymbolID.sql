/****** Object:  StoredProcedure [dbo].[GetNextLocalSymbolID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetNextLocalSymbolID
/****************************************************
**
**	Desc: Gets Next Available LocalSymbolID for a given paramFileID
**
**	Return values: 0: failure, otherwise, LocalSymbolID
**
**	Parameters: 
**
**		Auth: kja
**		Date: 08/10/2004
**    
*****************************************************/
(
		@ParamFileID int
)
As
	declare @LocalSymbolID int	
	
	SELECT @LocalSymbolID = MAX(Local_Symbol_ID) FROM T_Param_File_Mass_Mods
		WHERE (Param_File_ID = @ParamFileID)
		
	if @LocalSymbolID is null
	begin
		set @LocalSymbolID = 0
	end
		
	return(@LocalSymbolID + 1)

GO
