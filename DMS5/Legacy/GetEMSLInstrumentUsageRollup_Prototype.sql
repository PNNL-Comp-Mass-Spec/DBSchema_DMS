CREATE FUNCTION dbo.GetEMSLInstrumentUsageRollup
/****************************************************
**	Desc: 
**  Outputs contents of EMSL instrument usage report table as rollup
**
**	Return values: 
**
**	Parameters:
**	
**	Auth:	grk   
**	Date:	09/11/2012 grk - initial release
**    
*****************************************************/ 
( 
	@Year INT, 
	@Month INT 
)
RETURNS @TX TABLE
	(
	  [EMSL_Inst_ID] [int] ,
	  [Instrument] [varchar](64) ,
	  [Start] [datetime] ,
	  [Minutes] [int] ,
	  [Proposal] [varchar](32) ,
	  [Usage] [varchar](32) ,
	  [Users] [varchar](1024) ,
	  [Operator] [varchar](64) ,
	  [Comment] [varchar](4096) 
	)
AS 
	BEGIN
		DECLARE @date DATETIME = GETDATE()
		
		INSERT  INTO @TX ( 
				EMSL_Inst_ID ,
				Instrument ,
				Proposal ,
				Usage ,
				Users ,
				Operator ,
				Comment ,
				Minutes,
				Start			 
			)
			SELECT  EMSL_Inst_ID ,
					Instrument ,
					Proposal ,
					Usage ,
					Users ,
					Operator ,
					Comment ,
					SUM(Minutes) AS [Minutes], --  COUNT(*) AS Num
					@date AS [Start]			
			FROM    ( SELECT    TEIUR.EMSL_Inst_ID ,
								TEIUR.Instrument ,
								TEIUR.Proposal ,
								TEIUR.Usage ,
								TEIUR.Users ,
								TEIUR.Operator ,
								CASE WHEN Usage = 'ONSITE' THEN ''
									WHEN USAGE = 'MAINTENANCE'
									AND Dataset_Num LIKE 'QC_%'
									AND Type = 'dataset' THEN 'QC'
									ELSE Comment
								END AS Comment ,
								TEIUR.Minutes
						FROM      T_EMSL_Instrument_Usage_Report AS TEIUR
								LEFT OUTER JOIN T_Dataset AS TDS ON TDS.Dataset_ID = TEIUR.ID
						WHERE     ( TEIUR.Year = @Year )
								AND ( TEIUR.Month = @Month )
					) AS TX
			GROUP BY EMSL_Inst_ID ,
					Instrument ,
					Proposal ,
					Usage ,
					Users ,
					Operator ,
					Comment
			ORDER BY Instrument ,
					Proposal ,
					Usage 
		
		DECLARE @start DATETIME = CONVERT(VARCHAR(12), @month) + '/1/' + CONVERT(VARCHAR(12), @year)
		UPDATE @TX	
		SET @start = Start	= DATEADD(MINUTE, minutes, @start)
							
		RETURN
	END