/****** Object:  UserDefinedFunction [dbo].[GetOSMItemChooserList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetOSMItemChooserList]
/****************************************************
 **
 **	Desc: 
 **  Builds delimited list of item IDs
 **  for adding to OSM package
 **
 **	Return value: delimited list
 **
 **	Auth:	grk
 **	Date:
 **		10/26/2012 grk - initial release
 **		11/01/2012 grk - eliminated mode 'campaign_from_exp_group_parent'
 **		11/03/2012 grk - added mode 'datasets_from_completed_requested_runs'
**    
 *****************************************************/
(
 	@OSMPackageID int,
 	@mode varchar(128) = ''
)
 RETURNS varchar(8000)
 AS
 	BEGIN
 		---------------------------------------------------
 		-- temp table to accumulate items to be made into list
		---------------------------------------------------
 		DECLARE @tx TABLE (
 			Item varchar(512)
 		)
 		
 		declare @list varchar(8000) = ''

 		---------------------------------------------------
 		-- get items for list
		---------------------------------------------------
		IF @mode = 'campaign_from_exp_group_members'
 		BEGIN 
 			INSERT INTO @tx
 			        ( Item )	
 			SELECT  DISTINCT 
 					TCPN.Campaign_Num AS Item
 			FROM    S_V_OSM_Package_Items_Export AS TOPI
 					INNER JOIN T_Experiment_Group_Members AS TEGM ON TEGM.Group_ID = TOPI.Item_ID
 					INNER JOIN T_Experiments AS TEXP ON TEXP.Exp_ID = TEGM.Exp_ID
 					INNER JOIN T_Campaign AS TCPN ON TEXP.EX_campaign_ID = TCPN.Campaign_ID
 			WHERE   ( TOPI.Item_Type = 'Experiment_Groups' )
 			AND 	TOPI.OSM_Package_ID = @OSMPackageID
 			AND NOT TCPN.Campaign_Num = 'Placeholder'	
 		END 			        						
 
 		---------------------------------------------------
 		-- get items for list
		---------------------------------------------------
  		IF @mode = 'datasets_from_completed_requested_runs'
 		BEGIN 
 			INSERT INTO @tx
 			        ( Item )	
 			SELECT 
				TDS.Dataset_Num AS Item
			FROM    S_V_OSM_Package_Items_Export AS TOPI
			INNER JOIN T_Requested_Run TRR ON TRR.ID = TOPI.Item_ID
			INNER JOIN dbo.T_Dataset TDS ON TDS.Dataset_ID = TRR.DatasetID
			WHERE   ( TOPI.Item_Type = 'Requested_Runs' )
 			AND 	TOPI.OSM_Package_ID = @OSMPackageID
			AND NOT TDS.Dataset_Num IN 
 			(
  				SELECT 
					TDSX.Dataset_Num
				FROM    S_V_OSM_Package_Items_Export AS TOPIX
				INNER JOIN dbo.T_Dataset TDSX ON TDSX.Dataset_ID = TOPIX.Item_ID
				WHERE   ( TOPIX.Item_Type = 'Datasets' )
 				AND 	TOPIX.OSM_Package_ID = @OSMPackageID
			)
 		END 			        						

  		---------------------------------------------------
 		-- roll up items into delimited list
		---------------------------------------------------
		SELECT 
 			@list = @list + CASE WHEN @list = '' THEN Item ELSE ', ' + Item END
 		FROM @tx

 		RETURN ISNULL(@list,'')
 	END



GO
GRANT VIEW DEFINITION ON [dbo].[GetOSMItemChooserList] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetOSMItemChooserList] TO [DMS2_SP_User] AS [dbo]
GO
