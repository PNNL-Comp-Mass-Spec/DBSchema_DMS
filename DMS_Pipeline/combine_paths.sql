/****** Object:  UserDefinedFunction [dbo].[combine_paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[combine_paths]
/****************************************************
**  Appends a folder or file name to a path,
**   assuring that the two names are separated by a \
**
**  Auth:   mem
**  Date:   07/03/2006
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
****************************************************/
(
    @path1 varchar(2048),
    @path2 varchar(2048)
)
RETURNS varchar(4096)
AS
BEGIN
    Declare @NewPath varchar(4096)

    Set @Path1 = IsNull(@Path1, '')
    Set @Path2 = IsNull(@Path2, '')

    If Len(LTrim(RTrim(@Path1))) > 0
    Begin
        If Len(LTrim(RTrim(@Path2))) = 0
            Set @NewPath = @Path1
        Else
        Begin
            If Right(@Path1, 1) <> '\'
                Set @Path1 = @Path1 + '\'

            If Left(@Path2, 1) = '\'
                Set @Path2 = SubString(@Path2, 2, Len(@Path2)-1)

            Set @NewPath = @Path1 + @Path2
        End
    End
    Else
    Begin
        Set @NewPath = @Path2
    End

    RETURN  @NewPath
END

GO
GRANT VIEW DEFINITION ON [dbo].[combine_paths] TO [DDL_Viewer] AS [dbo]
GO
