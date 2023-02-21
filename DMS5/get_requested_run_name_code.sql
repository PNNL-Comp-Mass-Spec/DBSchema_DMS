/****** Object:  UserDefinedFunction [dbo].[get_requested_run_name_code] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[get_requested_run_name_code]
/****************************************************
**
**  Desc:
**      Generates the Name Code string for a given requested run
**      This string is used when grouping requested runs for run planning purposes
**
**      The request name code will be based on the request name, date, requester PRN, dataset type, and separation type if @batchID = 0
**      Otherwise, if @batchID is non-zero, it is based on the batch group ID, batch name, date, batch ID, dataset type, and separation type
**
**      Examples:
**          GCM_20210825_R_POIR043_18_GC
**          MoT_20210706_B_8050_13_LC-Acetylome
**
**  Return value: string
**
**  Auth:   mem
**  Date:   08/05/2010
**          08/10/2010 mem - Added @datasetTypeID and @separationType
**                         - Increased size of return string to varchar(64)
**          08/26/2021 mem - Use Batch ID instead of PRN
**          06/22/2022 mem - Remove parameter @batchRequesterPRN since unused
**          02/21/2023 mem - Rename function and add parameter @batchGroupID
**
*****************************************************/
(
    @requestName varchar(128),
    @requestCreated datetime,
    @requesterPRN varchar(64),
    @batchID int,
    @batchName varchar(128),
    @batchGroupID int,
    @batchCreated datetime,
    @datasetTypeID int,
    @separationType varchar(32)
)
RETURNS varchar(64)
AS
BEGIN
    RETURN CASE WHEN Coalesce(@batchID, 0) = 0
                THEN
                    SUBSTRING(@requestName, 1, 3) + '_' +
                    CONVERT(varchar(10), @requestCreated, 112) + '_' +
                    'R_' +
                    @requesterPRN + '_' +
                    CONVERT(varchar(4), ISNULL(@datasetTypeID, 0)) + '_' +
                    IsNull(@separationType, '')
                ELSE
                    CASE WHEN Coalesce(@batchGroupID, 0) > 0 
                         THEN CAST(@batchGroupID AS VarChar(12)) + '_' 
                         ELSE '' 
                    END +
                    SUBSTRING(@batchName, 1, 3) + '_' +
                    CONVERT(varchar(10), @batchCreated, 112) + '_' +
                    'B_' +
                    CAST(@batchID AS VarChar(12)) + '_' +
                    CONVERT(varchar(4), ISNULL(@datasetTypeID, 0)) + '_' +
                    IsNull(@separationType, '')

           END
END

GO
