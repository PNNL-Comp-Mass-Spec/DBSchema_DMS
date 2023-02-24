/****** Object:  UserDefinedFunction [dbo].[GetSamplePrepRequestEUSUsersList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetSamplePrepRequestEUSUsersList]
/****************************************************
**
**  Desc:   Builds delimited list of EUS users for given sample prep request
**
**          @mode = 'I' means return integer
**          @mode = 'N' means return name
**          @mode = 'V' means return hybrid in the form Person_Name (Person_ID)
**
**  Return value: delimited list
**
**  Auth:   mem
**  Date:   05/01/2014
**          03/17/2017 mem - Pass this procedure's name to udfParseDelimitedList
**          08/02/2018 mem - T_Sample_Prep_Request now tracks EUS User ID as an integer
**
*****************************************************/
(
    @requestID int,
    @mode char(1) = 'I'     -- 'I', 'N', or 'V'
)
RETURNS varchar(1024)
AS
Begin
    Declare @eusUserID int

    Declare @list varchar(1024) = ''

    SELECT @eusUserID = EUS_User_ID
    FROM T_Sample_Prep_Request
    WHERE ID = @requestID

    If IsNull(@eusUserID, 0) <= 0
    Begin
        Set @list = '(none)'
    End
    Else
    Begin
        IF @mode = 'I'
        BEGIN
            SELECT @list = CAST(EU.Person_ID AS varchar(12))
            FROM T_EUS_Users EU
            Where EU.PERSON_ID = @eusUserID
        END

        IF @mode = 'N'
        BEGIN
            SELECT @list = EU.NAME_FM
            FROM T_EUS_Users EU
            Where EU.PERSON_ID = @eusUserID
        END

        IF @mode = 'V'
        BEGIN
            SELECT @list = NAME_FM + ' (' + CAST(EU.PERSON_ID AS varchar(12)) + ')'
            FROM T_EUS_Users EU
            Where EU.PERSON_ID = @eusUserID

            if @list = '' set @list = '(none)'
        END
    End

    RETURN @list

END

GO
GRANT VIEW DEFINITION ON [dbo].[GetSamplePrepRequestEUSUsersList] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetSamplePrepRequestEUSUsersList] TO [public] AS [dbo]
GO
