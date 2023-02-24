/****** Object:  UserDefinedFunction [dbo].[get_instrument_name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_instrument_name]
/****************************************************
**
**  Desc: Gets InstrumentName for given instrument ID
**
**  Return values: "": failure, otherwise, instrument Name
**
**  Auth:   jds
**  Date:   07/01/2004
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @instrumentID int = 0
)
RETURNS varchar(24)
AS
BEGIN
    Declare @instrumentName varchar(80) = ' '

    SELECT @instrumentName = In_Name
    FROM T_Instrument_Name
    WHERE Instrument_ID = @instrumentID

    return @instrumentName
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_instrument_name] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_instrument_name] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_instrument_name] TO [Limited_Table_Write] AS [dbo]
GO
