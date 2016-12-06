/****** Object:  StoredProcedure [dbo].[CacheInstrumentsWithQCMetrics] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.CacheInstrumentsWithQCMetrics
/****************************************************
**
**	Desc:	Caches the names of Instruments that 
**			have data in table T_Dataset_QC
**
**			Used by the SMAQC website when it constructs the list of available instruments
**			http://prismsupport.pnl.gov/smaqc/index.php/smaqc/metric/P_2C/inst/VOrbi05/
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	11/04/2015 mem - Initial version
**
*****************************************************/
(
	@infoOnly tinyint = 0,
	@message varchar(512) = '' output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Set @infoOnly = IsNull(@infoOnly, 0)

	Create Table #Tmp_Instruments (Instrument_ID int NOT NULL)
	
	----------------------------------------
	-- First cache the instrument IDs in a temporary table
	-- Limiting to datasets that have data in T_Dataset_QC
	----------------------------------------

	INSERT INTO #Tmp_Instruments (Instrument_ID)
	SELECT DISTINCT DS.DS_instrument_name_ID
	FROM T_Dataset_QC DQC
	     INNER JOIN T_Dataset DS
	       ON DQC.Dataset_ID = DS.Dataset_ID
	--
	Select @myRowCount = @@RowCount, @myError = @@Error

	If @infoOnly <> 0
	Begin
		SELECT Inst.IN_Name, Inst.Instrument_ID
		FROM T_Instrument_Name Inst
		     INNER JOIN #Tmp_Instruments
		       ON Inst.Instrument_ID = #Tmp_Instruments.Instrument_ID

	End
	Else
	Begin
		----------------------------------------
		-- Update T_Dataset_QC_Instruments
		----------------------------------------

		MERGE T_Dataset_QC_Instruments AS target
		USING ( SELECT Inst.IN_Name, Inst.Instrument_ID
		        FROM T_Instrument_Name Inst
		             INNER JOIN #Tmp_Instruments
		               ON Inst.Instrument_ID = #Tmp_Instruments.Instrument_ID) as source
		ON ( target.IN_name = source.IN_name)
		WHEN MATCHED AND (target.Instrument_ID <> source.Instrument_ID)
		THEN UPDATE SET 
			Instrument_ID = source.Instrument_ID,
			Last_Updated = GetDate()
		WHEN NOT MATCHED BY TARGET THEN
			INSERT(IN_name, Instrument_ID, Last_Updated)
			VALUES(source.IN_name, source.Instrument_ID, GetDate())
		WHEN NOT MATCHED BY SOURCE THEN DELETE;
		--
		Select @myRowCount = @@RowCount, @myError = @@Error

	End

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[CacheInstrumentsWithQCMetrics] TO [DDL_Viewer] AS [dbo]
GO
