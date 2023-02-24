/****** Object:  UserDefinedFunction [dbo].[get_campaign_work_package_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_campaign_work_package_list]
/****************************************************
**
**  Desc:
**      Builds a delimited list of work packages for the given campaign
**
**  Return value: delimited list
**
**  Auth:   mem
**  Date:   06/07/2019 mem - Initial version
**          06/11/2022 mem - Exclude null values and empty strings from the list
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @campaignName Varchar(128)
)
RETURNS varchar(6000)
AS
    BEGIN
        Declare @list varchar(6000) = ''
        Declare @sep varchar(8) = ';'

        SELECT @list = @list + CASE WHEN @list = '' THEN ''
                                    ELSE @sep
                               END + LookupQ.WorkPackage
        FROM ( SELECT DISTINCT RR.RDS_WorkPackage AS WorkPackage
               FROM T_Requested_Run RR
                    INNER JOIN T_Dataset DS
                      ON RR.DatasetID = DS.Dataset_ID
                    INNER JOIN T_Experiments E
                      ON DS.Exp_ID = E.Exp_ID
                    INNER JOIN T_Campaign C
                      ON E.EX_campaign_ID = C.Campaign_ID
               WHERE C.Campaign_Num = @campaignName And
                     Len(Ltrim(Rtrim(Coalesce(RR.RDS_WorkPackage, '')))) > 0
             ) LookupQ

        RETURN @list
    END

GO
