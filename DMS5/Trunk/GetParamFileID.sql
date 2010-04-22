/****** Object:  StoredProcedure [dbo].[GetParamFileID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetParamFileID
/****************************************************
**
**	Desc: Gets ParamFileID for given ParamFileName
**
**	Return values: 0: failure, otherwise, ParamFileID
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	01/26/2001
**			02/12/2010 mem - Increased size of @ParamFileName to varchar(255)
**    
*****************************************************/
(
	@ParamFileName varchar(255) = " "
)
As
	declare @ParamFileID int
	
	set @ParamFileID = 0

	SELECT @ParamFileID = Param_File_ID
	FROM T_Param_Files
	WHERE (Param_File_Name = @ParamFileName)

	Return @ParamFileID

GO
GRANT EXECUTE ON [dbo].[GetParamFileID] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetParamFileID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetParamFileID] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetParamFileID] TO [PNL\D3M580] AS [dbo]
GO
