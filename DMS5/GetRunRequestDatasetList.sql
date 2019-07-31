/****** Object:  UserDefinedFunction [dbo].[GetRunRequestDatasetList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[GetRunRequestDatasetList]
/****************************************************
**
**  Desc: Return a table with dataset names associated with an analysis job request
**
**  Auth:   grk
**  Date:   11/09/2005 grk - Initial release
**          05/03/2012 mem - Updated @entryList to varchar(max)
**          07/30/2019 mem - Get Dataset IDs from T_Analysis_Job_Request_Datasets
**
*****************************************************/
(
    @requestID int
)
RETURNS @datasets TABLE
(
    dataset varchar(128)
)
AS
    Begin
        INSERT INTO @datasets( dataset )
        SELECT DS.Dataset_Num
        FROM T_Analysis_Job_Request_Datasets AJRD
             INNER JOIN T_Dataset DS
               ON AJRD.Dataset_ID = DS.Dataset_ID
        WHERE (Request_ID = @requestID)
        ORDER BY DS.Dataset_Num

        RETURN
    END

GO
GRANT VIEW DEFINITION ON [dbo].[GetRunRequestDatasetList] TO [DDL_Viewer] AS [dbo]
GO
