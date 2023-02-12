/****** Object:  UserDefinedFunction [dbo].[GetOSMPackageItemComment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetOSMPackageItemComment]
/****************************************************
**
**	Desc: 
**  Returns starting date for fiscal year N years ago
**
**	Return value: person
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	03/18/2013
**    
*****************************************************/
(
    @itemId INT = 3988 ,
    @itemType VARCHAR(64) = 'Material_Containers' 
)
RETURNS VARCHAR(2048) 
AS
BEGIN
	DECLARE 
    @itemComment VARCHAR(2048) = ''

	IF @itemType = 'Material_Containers' 
    BEGIN 
        SELECT  @itemComment = 'Container:' + ISNULL(TMC.Comment, '') + ', Location:' + ISNULL(TML.Comment, '')
        FROM    T_Material_Containers TMC
        INNER JOIN dbo.T_Material_Locations TML ON TMC.Location_ID = TML.ID
        WHERE   ( TMC.ID = @itemId )
    END 

	RETURN @itemComment
END



GO
GRANT VIEW DEFINITION ON [dbo].[GetOSMPackageItemComment] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetOSMPackageItemComment] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetOSMPackageItemComment] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetOSMPackageItemComment] TO [DMS2_SP_User] AS [dbo]
GO
