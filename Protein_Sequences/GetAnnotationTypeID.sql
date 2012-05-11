/****** Object:  StoredProcedure [dbo].[GetAnnotationTypeID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetAnnotationTypeID
/****************************************************
**
**	Desc: Gets AnnotationTypeID for a given Annotation Name
**
**
**	Parameters: 
**
**		Auth: kja
**		Date: 01/11/2006
**    
*****************************************************/
(
	@annName varchar(64),
	@authID int
)
As
	declare @annType_id int
	set @annType_id = 0
	
	SELECT @annType_id = Annotation_Type_ID FROM T_Annotation_Types
	 WHERE (TypeName = @annName and Authority_ID = @authID)
	
	return @annType_id

GO
GRANT EXECUTE ON [dbo].[GetAnnotationTypeID] TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetAnnotationTypeID] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
