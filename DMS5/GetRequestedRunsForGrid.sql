/****** Object:  StoredProcedure [dbo].[GetRequestedRunsForGrid] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetRequestedRunsForGrid]
/****************************************************
**
**	Desc: 
**		Returns the info for with the
**		run requests given by the itemList
**
**	Auth:	grk
**	Date:	01/13/2013
**	01/13/2013 grk - initial release
**    
*****************************************************/
(
	@itemList TEXT,
	@message varchar(512)='' OUTPUT
)
AS
	Set NoCount On

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0
	
	-----------------------------------------
	-- convert item list into temp table
	-----------------------------------------
	--
	CREATE TABLE #ITEMS (
		Item VARCHAR(128)
	)
	--
	INSERT INTO #ITEMS (Item)
	SELECT Item 
	FROM .MakeTableFromList(@itemList)

	-----------------------------------------
	-- 
	-----------------------------------------


	-----------------------------------------
	-- 
	-----------------------------------------
	
/*
Request varchar(8),
Name varchar(128),
Status varchar(128),
BatchID varchar(8),
Instrument varchar(64),
Separation_Type varchar(128),
Experiment varchar(128),
Cart varchar(128),
Column varchar(8),
Block varchar(32),
Run_Order varchar(8)	
*/	
	-----------------------------------------
	-- 
	-----------------------------------------

	SELECT  
		TRR.ID AS Request ,
		TRR.RDS_Name AS Name ,
		TRR.RDS_Status AS Status ,
			TRR.RDS_BatchID AS BatchID ,
		TRR.RDS_instrument_name AS Instrument ,
		TRR.RDS_Sec_Sep AS Separation_Type ,
		TEX.Experiment_Num AS Experiment ,
		T_LC_Cart.Cart_Name AS Cart ,
		TRR.RDS_Cart_Col AS [Column],
		TRR.RDS_Block AS Block ,
		TRR.RDS_Run_Order AS Run_Order
	FROM    
	T_Requested_Run TRR
		INNER JOIN T_LC_Cart ON TRR.RDS_Cart_ID = T_LC_Cart.ID
		INNER JOIN T_Requested_Run_Batches TRB ON TRR.RDS_BatchID = TRB.ID
		INNER JOIN T_Experiments TEX ON TRR.Exp_ID = TEX.Exp_ID
	WHERE
		TRR.RDS_Status = 'Active'
		AND TRR.ID IN (SELECT Item FROM #ITEMS)
		
	RETURN @myError	

GO
GRANT EXECUTE ON [dbo].[GetRequestedRunsForGrid] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetRequestedRunsForGrid] TO [DMS2_SP_User] AS [dbo]
GO
