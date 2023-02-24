/****** Object:  UserDefinedFunction [dbo].[get_instrument_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_instrument_id]
/****************************************************
**
**  Desc: Gets InstrumentID for given instrument name
**
**  Return values: 0: failure, otherwise, instrument ID
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @instrumentName varchar(80) = " "
)
RETURNS int
AS
BEGIN
    Declare @instrumentID int = 0

    SELECT @instrumentID = Instrument_ID
    FROM T_Instrument_Name
    WHERE IN_name = @instrumentName

    return @instrumentID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_instrument_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_instrument_id] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_instrument_id] TO [Limited_Table_Write] AS [dbo]
GO
