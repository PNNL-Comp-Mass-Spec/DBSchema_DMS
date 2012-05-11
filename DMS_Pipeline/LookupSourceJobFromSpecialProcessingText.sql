/****** Object:  StoredProcedure [dbo].[LookupSourceJobFromSpecialProcessingText] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE LookupSourceJobFromSpecialProcessingText
/****************************************************
** 
**	Desc:	Parses the special processing text in @SpecialProcessingText
**			to determine the source job defined for a new job
**
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	mem
**	Date:	05/03/2012 mem - Initial version (extracted from LookupSourceJobFromSpecialProcessingParam)
**			05/04/2012 mem - Added parameters @TagName and @AutoQueryUsed
**						   - Removed the SourceJobResultsFolder parameter
**    
*****************************************************/
(
	@Job int,
	@Dataset varchar(255),
	@SpecialProcessingText varchar(1024),
	@TagName varchar(12) = 'SourceJob',					-- Typically 'SourceJob' or Job2'
	@SourceJob int = 0 output,
	@AutoQueryUsed tinyint = 0 output,
	@WarningMessage varchar(512) = '' output,
	@PreviewSql tinyint = 0
)
As
	Set nocount on
	
	declare @myError int
	declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	Declare @SourceJobText varchar(255)

	Declare @IndexStart int
	Declare @IndexEnd int

	Declare @S nvarchar(2048) = ''
	Declare @sqlParams nvarchar(1024) = ''

	Declare @WhereClause varchar(1024) = ''
	Declare @OrderBy varchar(32) = ''

	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'
	
	------------------------------------------------
	-- Validate the inputs
	------------------------------------------------

	Set @SpecialProcessingText = IsNull(@SpecialProcessingText, '')
	Set @TagName = IsNull(@TagName, 'SourceJob')
	Set @PreviewSql = IsNull(@PreviewSql, 0)
	
	Set @SourceJob = 0
	Set @AutoQueryUsed = 0
	Set @WarningMessage = ''
	
	Begin Try
		If @TagName Not Like '%:'
			Set @TagName = @TagName + ':'
			
		------------------------------------------------
		-- Parse the Special_Processing text to extract out the source job info
		------------------------------------------------
		Set @SourceJobText = dbo.ExtractTaggedName(@TagName, @SpecialProcessingText)

		If IsNumeric(@SourceJobText) > 0
			Set @SourceJob = Convert(int, @SourceJobText)
		Else
		Begin -- <d>
			-- @SourceJobText is non-numeric
			
			If @SourceJobText Like 'Auto%'
			Begin -- <e>
				-- Parse @SpecialProcessingText to look for @TagName:Auto  (Note that we must process @SpecialProcessingText since @SourceJobText won't have the full text)
				-- Then find { and }
				-- The text between { and } will be used as a Where clause to query S_DMS_V_Analysis_Job_Info to find the best job for this dataset
				-- Example:
				--  SourceJob:Auto{Tool = "Decon2LS_V2" AND Settings_File = "Decon2LS_FF_IMS_UseHardCodedFilters_20ppm_NoFlags_2011-02-04.xml"}
				--
				-- Example 2:				
				--  SourceJob:Auto{Tool = "XTandem" AND Settings_File = "IonTrapDefSettings_DeconMSN_CIDOnly.xml" AND [Parm File] = "xtandem_Rnd1PartTryp_Rnd2DynMetOx.xml"}, Job2:Auto{Tool = "MASIC_Finnigan"}
				
				Set @AutoQueryUsed = 1				
				Set @IndexStart = CharIndex(@TagName + 'Auto', @SpecialProcessingText)

				If @IndexStart > 0
				Begin -- <f>
					Set @WhereClause = SUBSTRING(@SpecialProcessingText, @IndexStart + LEN(@TagName + 'Auto'), LEN(@SpecialProcessingText))

					-- Replace double quotes with single quotes
					set @WhereClause = REPLACE(@WhereClause, '"', '''')
					
					Set @IndexStart = CHARINDEX('{', @WhereClause)
					Set @IndexEnd = CHARINDEX('}', @WhereClause)
					
					If @IndexStart > 0 And @IndexEnd > @IndexStart
						Set @WhereClause = SUBSTRING(@WhereClause, @IndexStart+1, @IndexEnd-@IndexStart-1)
					Else
						Set @WhereClause= ''
						
					Set @WhereClause = 'WHERE Dataset = ''' + @Dataset + ''' AND ' + @WhereClause
					
					-- By default, order by Job Descending
					-- However, if @WhereClause already contains ORDER BY then we don't want to add another one
					If @WhereClause LIKE '%ORDER BY%'
						Set @OrderBy = ''
					Else
						Set @OrderBy = 'ORDER BY Job Desc'
					
					-- Note that S_DMS_V_Analysis_Job_Info uses V_Source_Analysis_Job in DMS
					Set @S = 'SELECT TOP 1 @SourceJob=Job FROM S_DMS_V_Analysis_Job_Info ' + @WhereClause + ' ' + @OrderBy
					
					Set @sqlParams = '@SourceJob int output'
					
					If @PreviewSql <> 0
						Print @S

					exec sp_executesql @S, @sqlParams, @SourceJob = @SourceJob output
					
					If @SourceJob = 0
					Begin
						Set @WarningMessage = 'Unable to determine SourceJob for job ' + Convert(varchar(12), @Job) + ' using query ' + @S
					End
												
				End -- </f>
				
			End -- </e>
			
			If @WhereClause = '' And @WarningMessage = ''
			Begin
				Set @WarningMessage = @TagName + ' tag is not numeric in the Special_Processing parameter for job ' + Convert(varchar(12), @Job)
				Set @warningMessage = @WarningMessage + '; alternatively, can be ' + @TagName + 'Auto{SqlWhereClause} where SqlWhereClause is the where clause to use to select the best analysis job for the given dataset using S_DMS_V_Analysis_Job_Info'
			End
		End -- </d>

	End Try
	Begin Catch
		-- Error caught; log the error, then continue with the next job
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'LookupSourceJobFromSpecialProcessingText')
		If @WhereClause <> ''
			Set @CurrentLocation = @CurrentLocation + '; using Sql Where Clause (see separate log entry)'
		
		Declare @message varchar(512)		
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
		
		If @WhereClause <> ''
		Begin
			Set @WarningMessage = 'Query for SourceJob determination for job ' + Convert(varchar(12), @Job) + ': ' + @S
			execute PostLogEntry 'Debug', @WarningMessage, 'LookupSourceJobFromSpecialProcessingText'
		End
		
		If @WarningMessage = ''
			Set @WarningMessage = 'Exception while determining SourceJob and/or results folder'
			
	End Catch	

	return @myError

GO
