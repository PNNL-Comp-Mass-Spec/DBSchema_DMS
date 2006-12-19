/****** Object:  StoredProcedure [dbo].[ReportProductionStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ReportProductionStats
/****************************************************
**
**	Desc: Generates dataset statistics for production instruments
**
**	Return values: 0: success, otherwise, error code
**
**		Auth: grk
**		Date: 2/25/2005
**             3/1/2005   grk added column for instrument name at end
**             12/19/2005 added "MD" and "TS" prefixes (ticket #345)
**    
*****************************************************/
	@startDate varchar(24),
	@endDate varchar(24),
	@message varchar(256) output
AS
	SET NOCOUNT ON

	declare @daysInRange float
	declare @stDate datetime
	declare @eDate datetime

	set @stDate = CONVERT(DATETIME, @startDate, 102)
	set @eDate = CONVERT(DATETIME, @endDate, 102)
	set @daysInRange = DateDiff(dd, @stDate, @eDate)

	---------------------------------------------------
	-- Generate report
	---------------------------------------------------

	SELECT
		Instrument,
		[Total] as [Total Datasets],
		@daysInRange as [Days in range],
		convert(decimal(5,1), [Total]/@daysInRange) as [Datasets per day],
		[Blank] as [Blank Datasets],
		[QC] as [QC Datasets],
		[MD] as [Method Dev.],
		[TS] as [Troubleshooting],
		[Bad] as [Bad Datasets],
		convert(decimal(5,1), ([QC] * 100.0/[Total])) as [% QC Datasets],
		convert(decimal(5,1), ([Bad] * 100.0/[Total])) as [% Bad Datasets],
		[Total] - ([Blank] + [QC] + [Bad]) as [Study Specific Datasets ],
		convert(decimal(5,1), ([Total] - ([Blank] + [QC] + [Bad])) / @daysInRange) as [Study Specific Datasets per day],
		Instrument as [Inst.]
	FROM
	(
		SELECT
		T_Instrument_Name.IN_Name as Instrument, 
		COUNT(*) AS [Total],
		SUM(CASE WHEN T_Dataset.Dataset_Num LIKE 'Blank%' THEN 1 ELSE 0 END) AS [Blank],
		SUM(CASE WHEN T_Dataset.Dataset_Num LIKE 'Bad%' THEN 1 ELSE 0 END) AS [Bad],
		SUM(CASE WHEN T_Dataset.Dataset_Num LIKE 'QC%' THEN 1 ELSE 0 END) AS [QC],
		SUM(CASE WHEN T_Dataset.Dataset_Num LIKE 'MD%' THEN 1 ELSE 0 END) AS [MD],
		SUM(CASE WHEN T_Dataset.Dataset_Num LIKE 'TS%' THEN 1 ELSE 0 END) AS [TS]
		FROM
			T_Dataset INNER JOIN
			T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
		WHERE
			T_Instrument_Name.IN_operations_role = 'Production' AND
			T_Dataset.DS_created BETWEEN @stDate AND @eDate
		GROUP BY T_Instrument_Name.IN_Name
	) X ORDER BY Instrument


	RETURN

GO
GRANT EXECUTE ON [dbo].[ReportProductionStats] TO [DMS_User]
GO
