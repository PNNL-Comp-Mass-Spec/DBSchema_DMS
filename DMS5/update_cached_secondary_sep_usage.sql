/****** Object:  StoredProcedure [dbo].[UpdateCachedSecondarySepUsage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE UpdateCachedSecondarySepUsage
/****************************************************
**
**	Desc:	Updates the data in T_Secondary_Sep_Usage
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	11/18/2015 mem - Initial Version
**			02/23/2016 mem - Add set XACT_ABORT on
**
*****************************************************/
(
	@message varchar(255) = '' output
)
AS

	Set XACT_ABORT, nocount on

	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	set @message = ''

	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'	
	
	Begin Try
		
		set ansi_warnings off
		
		MERGE T_Secondary_Sep_Usage AS t
		USING (SELECT 
					SS.SS_ID,
					SUM(CASE
							WHEN datediff(MONTH, DS.DS_Created, getdate()) <= 12 THEN 1
							ELSE 0
						END) AS Usage_Last12Months,
					SUM(CASE
							WHEN DS.Dataset_ID IS NULL THEN 0
							ELSE 1
						END) AS Usage_AllYears,
					MAX(DS.DS_created) AS Most_Recent_Use
				FROM T_Secondary_Sep SS
					 LEFT OUTER JOIN T_Dataset DS
					   ON DS.DS_sec_sep = SS.SS_name	   
				GROUP BY SS.SS_ID, SS.SS_name
		) AS s
		ON ( t.SS_ID = s.SS_ID)
		WHEN MATCHED AND (
			ISNULL( NULLIF(t.Usage_Last12Months, s.Usage_Last12Months),
					NULLIF(s.Usage_Last12Months, t.Usage_Last12Months)) IS NOT NULL OR
			ISNULL( NULLIF(t.Usage_AllYears, s.Usage_AllYears),
					NULLIF(s.Usage_AllYears, t.Usage_AllYears)) IS NOT NULL OR
			ISNULL( NULLIF(t.Most_Recent_Use, s.Most_Recent_Use),
					NULLIF(s.Most_Recent_Use, t.Most_Recent_Use)) IS NOT NULL
			)
		THEN UPDATE SET 
			Usage_Last12Months = s.Usage_Last12Months,
			Usage_AllYears = s.Usage_AllYears,
			Most_Recent_Use = s.Most_Recent_Use
		WHEN NOT MATCHED BY TARGET THEN
			INSERT(SS_ID, Usage_Last12Months, Usage_AllYears, Most_Recent_Use)
			VALUES(s.SS_ID, s.Usage_Last12Months, s.Usage_AllYears, s.Most_Recent_Use)
		WHEN NOT MATCHED BY SOURCE THEN DELETE;
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
 
		set ansi_warnings on
		
		If @myError <> 0
		begin
			set @message = 'Error updating T_Secondary_Sep_Usage via merge (ErrorID = ' + Convert(varchar(12), @myError) + ')'
			execute PostLogEntry 'Error', @message, 'UpdateCachedSecondarySepUsage'
			goto Done
		end

	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateCachedSecondarySepUsage')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
		Goto Done		
	End Catch
			
Done:
	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCachedSecondarySepUsage] TO [DDL_Viewer] AS [dbo]
GO
