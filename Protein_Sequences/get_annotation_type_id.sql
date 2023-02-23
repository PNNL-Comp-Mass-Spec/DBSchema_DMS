/****** Object:  StoredProcedure [dbo].[get_annotation_type_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_annotation_type_id]
/****************************************************
**
**  Desc: Gets AnnotationTypeID for a given Annotation Name
**
**
**  Parameters:
**
**  Auth:   kja
**  Date:   01/11/2006
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @annName varchar(64),
    @authID int
)
AS
    declare @annType_id int
    set @annType_id = 0

    SELECT @annType_id = Annotation_Type_ID FROM T_Annotation_Types
     WHERE (TypeName = @annName and Authority_ID = @authID)

    return @annType_id

GO
GRANT EXECUTE ON [dbo].[get_annotation_type_id] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
