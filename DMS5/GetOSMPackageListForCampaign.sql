/****** Object:  UserDefinedFunction [dbo].[GetOSMPackageListForCampaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[GetOSMPackageListForCampaign]
/****************************************************
**
**	Desc: 
**  Builds delimited list of OSM packages
**  for given campaign
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: grk
**		Date: 11/26/2012
**		11/26/2012 grk - initial release
**    
*****************************************************/
(
	@campaignID int
)
RETURNS varchar(8000)
AS
	BEGIN
		declare @list varchar(8000) = ''
		
		SELECT 
		@list = @list + CASE WHEN @list = '' THEN '' ELSE ', ' END + CONVERT(VARCHAR(12), OSM_Package_ID)
		FROM S_V_OSM_Package_Items_Export
		WHERE Item_Type = 'Campaigns' AND Item_ID = @campaignID

		RETURN @list
	END



GO
