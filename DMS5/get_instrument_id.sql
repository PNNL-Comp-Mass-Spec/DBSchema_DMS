/****** Object:  StoredProcedure [dbo].[GetInstrumentID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetInstrumentID]
/****************************************************
**
**  Desc: Gets InstrumentID for given instrument name
**
**  Return values: 0: failure, otherwise, instrument ID
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add Set NoCount On
**
*****************************************************/
(
    @instrumentName varchar(80) = " "
)
AS
    Set NoCount On

    Declare @instrumentID int = 0

    SELECT @instrumentID = Instrument_ID
    FROM T_Instrument_Name
    WHERE IN_name = @instrumentName

    return @instrumentID
GO
GRANT VIEW DEFINITION ON [dbo].[GetInstrumentID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetInstrumentID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetInstrumentID] TO [Limited_Table_Write] AS [dbo]
GO
