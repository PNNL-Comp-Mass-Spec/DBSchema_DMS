/****** Object:  StoredProcedure [dbo].[RetireStaleLCColumns] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RetireStaleLCColumns
/****************************************************
**
**	Desc: 
**		Automatically retires (sets inactive) LC columns that have not been used recently
**
**	Return values: 0:  success, otherwise, error code
**
**	Auth:	mem
**	Date:	01/23/2015
**    
*****************************************************/
(
	@infoOnly tinyint = 1,
	@message varchar(512) = '' output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowcount int
	set @myRowcount = 0
	set @myError = 0

	-----------------------------------------------------------
	-- Validate the inputs
	-----------------------------------------------------------
	
	Set @infoOnly = IsNull(@infoOnly, 1)
	Set @message = ''
	
	Declare @UsedThresholdMonths smallint = 9
	Declare @UnusedThresholdMonths smallint = 24


	-----------------------------------------------------------
	-- Create a temporary table to track the columns to retire
	-----------------------------------------------------------

	CREATE TABLE #Tmp_LCColumns (
		ID int not null primary key,
		Last_Used datetime not null,
		Most_Recent_Dataset varchar(128) null
	)
		
	-----------------------------------------------------------
	-- Find LC columns that have been used with a dataset, but not in the last 9 months
	-----------------------------------------------------------
	--
	INSERT INTO #Tmp_LCColumns (ID, Last_Used)
	SELECT LCCol.ID, Max(DS.DS_Created) as Last_Used
	FROM T_LC_Column LCCol
	     INNER JOIN T_Dataset DS
	       ON LCCol.ID = DS.DS_LC_column_ID
	WHERE LCCol.SC_State <> 3 AND
	      LCCol.SC_Created < DATEADD(month, -@UsedThresholdMonths, GETDATE()) AND
	      DS.DS_created < DATEADD(month, -@UsedThresholdMonths, GETDATE())
	GROUP BY LCCol.ID
	ORDER BY LCCol.ID
	
	
	If @infoOnly <> 0
	Begin
	
		-- Populate column Most_Recent_Dataset
		--	
		UPDATE #Tmp_LCColumns
		SET Most_Recent_Dataset = LookupQ.Dataset_Num
		FROM #Tmp_LCColumns
			INNER JOIN ( SELECT DS_LC_Column_ID,
								Dataset_Num,
								DS_Created
						FROM ( SELECT DS_LC_Column_ID,
										Dataset_Num,
										DS_Created,
										Row_Number() OVER ( 
											Partition BY ds_lc_column_id 
											ORDER BY ds_created DESC ) AS DatasetRank
								FROM T_Dataset
								WHERE DS_LC_Column_ID IN ( SELECT ID
															FROM #Tmp_LCColumns ) 
								) RankQ
						WHERE DatasetRank = 1 
						) LookupQ
			ON #Tmp_LCColumns.ID = LookupQ.DS_LC_Column_ID
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
	End

	-----------------------------------------------------------
	-- Next find LC columns created at least 2 years ago that have never been used with a dataset
	-----------------------------------------------------------
	--
	INSERT INTO #Tmp_LCColumns (ID, Last_Used)
	SELECT LCCol.ID, LCCol.SC_Created as Last_Used
	FROM T_LC_Column LCCol
	     LEFT OUTER JOIN T_Dataset DS
	       ON LCCol.ID = DS.DS_LC_column_ID
	WHERE LCCol.SC_State <> 3 AND
	      LCCol.SC_Created < DATEADD(MONTH, -@UnusedThresholdMonths, GETDATE()) AND
	      DS.Dataset_ID Is Null
	ORDER BY LCCol.ID

	-----------------------------------------------------------
	-- Remove certain columns that we don't want to auto-retire
	-----------------------------------------------------------
	--
	DELETE FROM #Tmp_LCColumns
	WHERE ID IN ( SELECT ID
	              FROM T_LC_Column
	              WHERE (SC_Column_Number IN ('unknown', 'No_Column', 'DI', 'Infuse')) )

	
	If @infoOnly <> 0
	Begin
		-----------------------------------------------------------
		-- Preview the columns that would be retired
		-----------------------------------------------------------
		--
		SELECT LCCol.ID,
		       LCCol.SC_Column_Number,
		       Src.Last_Used,
		       Src.Most_Recent_Dataset,
		       LCCol.SC_Created,
		       LCCol.SC_Comment,
		       LCCol.SC_Packing_Mfg,
		       LCCol.SC_Packing_Type,
		 LCCol.SC_Particle_size,
		       LCCol.SC_Particle_type,
		       LCCol.SC_Column_Inner_Dia,
		       LCCol.SC_Column_Outer_Dia
		FROM T_LC_Column LCCol
		     INNER JOIN #Tmp_LCColumns Src
		       ON LCCol.ID = Src.ID
		ORDER BY  Src.Last_Used, LCCol.ID

	End
	Else
	Begin
		-----------------------------------------------------------
		-- Change the LC Column state to 3=Retired
		-----------------------------------------------------------
		--
		UPDATE T_LC_Column
		SET SC_State = 3
		WHERE ID IN ( SELECT ID
		              FROM #Tmp_LCColumns Filter )
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @myRowCount > 0
		Begin
			Set @message = 'Retired ' + Cast(@myRowCount as varchar(12)) + dbo.CheckPlural(@myRowCount, ' LC column', ' LC columns') + ' that have not been used in at last ' + Cast(@UsedThresholdMonths as varchar(6)) + ' months'
			exec PostLogEntry 'Normal', @message, 'RetireStaleLCColumns'
		End
		
	End
	   
Done:
	Return @myError

GO
