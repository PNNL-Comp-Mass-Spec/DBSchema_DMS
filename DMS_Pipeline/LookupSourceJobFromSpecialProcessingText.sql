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
**			07/12/2012 mem - Added support for $ThisDataset in an Auto-query Where Clause
**			07/13/2012 mem - Added support for $Replace(x,y,z) in an Auto-query Where Clause
**			01/14/2012 mem - Added support for $ThisDatasetTrimAfter(x) in an Auto-query Where Clause
**			03/11/2013 mem - Added output parameter @AutoQuerySql
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/06/2016 mem - Now using Try_Convert to convert from text to int
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
	@PreviewSql tinyint = 0,
	@AutoQuerySql nvarchar(2048) = '' output			-- The auto-query SQL that was used
)
As
	Set XACT_ABORT, nocount on
	
	declare @myError int
	declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	Declare @SourceJobText varchar(255)

	Declare @IndexStart int
	Declare @IndexEnd int

	Declare @sqlParams nvarchar(1024) = ''

	Declare @WhereClause varchar(1024) = ''
	Declare @OrderBy varchar(32) = ''

	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'

	Declare @Part1 varchar(1024) = ''
	Declare @Part2 varchar(1024) = ''
	Declare @Part3 varchar(1024) = ''

	Declare @TextToSearch varchar(512)
	Declare @TextToFind varchar(512)
	Declare @Replacement varchar(512)

	------------------------------------------------
	-- Validate the inputs
	------------------------------------------------

	Set @SpecialProcessingText = IsNull(@SpecialProcessingText, '')
	Set @TagName = IsNull(@TagName, 'SourceJob')
	Set @PreviewSql = IsNull(@PreviewSql, 0)
	
	Set @SourceJob = 0
	Set @AutoQueryUsed = 0
	Set @WarningMessage = ''
	Set @AutoQuerySql = ''
	
	Begin Try
		If @TagName Not Like '%:'
			Set @TagName = @TagName + ':'
			
		------------------------------------------------
		-- Parse the Special_Processing text to extract out the source job info
		------------------------------------------------
		Set @SourceJobText = dbo.ExtractTaggedName(@TagName, @SpecialProcessingText)

		If IsNull(@SourceJobText, '') <> ''
			Set @SourceJob = Try_Convert(int, @SourceJobText)
			
		If @SourceJob Is Null
		Begin -- <d>
			-- @SourceJobText is non-numeric
			
			If @SourceJobText Like 'Auto%'
			Begin -- <e>
				-- Parse @SpecialProcessingText to look for		:Auto  (Note that we must process @SpecialProcessingText since @SourceJobText won't have the full text)
				-- Then find { and }
				-- The text between { and } will be used as a Where clause to query S_DMS_V_Analysis_Job_Info to find the best job for this dataset
				-- Example:
				--  SourceJob:Auto{Tool = "Decon2LS_V2" AND Settings_File = "Decon2LS_FF_IMS_UseHardCodedFilters_20ppm_NoFlags_2011-02-04.xml"}
				--
				-- Example 2:
				--  SourceJob:Auto{Tool = "XTandem" AND Settings_File = "IonTrapDefSettings_DeconMSN_CIDOnly.xml" AND [Parm File] = "xtandem_Rnd1PartTryp_Rnd2DynMetOx.xml"}, Job2:Auto{Tool = "MASIC_Finnigan"}
				--
				-- Example 3:
				--  SourceJob:Auto{Tool = "Decon2LS_V2" AND [Parm File] = "LTQ_FT_Lipidomics_2012-04-16.xml"}, Job2:Auto{Tool = "Decon2LS_V2" AND [Parm File] = "LTQ_FT_Lipidomics_2012-04-16.xml" AND Dataset LIKE "$Replace($ThisDataset,_Pos,)%NEG"}
				
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
					
					If @WhereClause Like '%$ThisDataset%'
					Begin
						-- The Where Clause contains a Dataset filter clause utilizing this dataset's name
						
						If @WhereClause Like '%$ThisDatasetTrimAfter%'
						Begin  -- <g1>
							-- The Where Clause contains a command of the form: $ThisDatasetTrimAfter(_Pos)
							-- Find the specified characters in the dataset's name and remove any characters that follow them
							-- Parse out the $ThisDatasetTrimAfter command and the text inside the parentheses just after the command
							
							Set @IndexStart = CHARINDEX('$ThisDatasetTrimAfter', @WhereClause)
							Set @IndexEnd = CHARINDEX(')', @WhereClause, @IndexStart)

							If @IndexStart > 0 And @IndexEnd > @IndexStart
							Begin -- <h1>

								Set @Part1 = SUBSTRING(@WhereClause, 1, @IndexStart-1)
								Set @Part2 = SUBSTRING(@WhereClause, @IndexStart, @IndexEnd - @IndexStart+1)
								Set @Part3 = SUBSTRING(@WhereClause, @IndexEnd+1, LEN(@WhereClause))
								
								-- The DatasetTrimmed directive is now in @Part2, for example: $ThisDatasetTrimAfter(_Pos)
								-- Parse out the text between the parentheses
							
								Set @IndexStart = CHARINDEX('(', @Part2)
								Set @IndexEnd = CHARINDEX(')', @Part2, @IndexStart)				

								If @IndexStart > 0 And @IndexEnd > @IndexStart
								Begin -- <i1>
									Set @TextToFind = SUBSTRING(@Part2, @IndexStart+1, @IndexEnd - @IndexStart-1)

									Set @IndexStart = CHARINDEX(@TextToFind, @Dataset)
																		
									If @IndexStart > 0
									Begin
										Set @Dataset = SUBSTRING(@Dataset, 1, @IndexStart+LEN(@TextToFind)-1)
									End
									
								End -- <i1>
								
							End -- </h1>							
							
							Set @WhereClause = @Part1 + @Dataset + @Part3
							Set @WhereClause = 'WHERE (' + @WhereClause + ')'
							
						End  -- </g1>
						Else
						Begin
							Set @WhereClause = Replace(@WhereClause, '$ThisDataset', @Dataset)
							Set @WhereClause = 'WHERE (' + @WhereClause + ')'
						End
					End
					Else
					Begin
						Set @WhereClause = 'WHERE (Dataset = ''' + @Dataset + ''') AND (' + @WhereClause + ')'
					End

					If @WhereClause Like '%$Replace(%'
					Begin -- <g2>
						-- The Where Clause contains a Replace Text command of the form: $Replace(DatasetName,'_Pos','') or $Replace(DatasetName,_Pos,)
						-- First split up the where clause to obtain the text before and after the replacement directive
						
						Set @IndexStart = CHARINDEX('$Replace', @WhereClause)
						Set @IndexEnd = CHARINDEX(')', @WhereClause, @IndexStart)

						If @IndexStart > 0 And @IndexEnd > @IndexStart
						Begin -- <h2>

							Set @Part1 = SUBSTRING(@WhereClause, 1, @IndexStart-1)
							Set @Part2 = SUBSTRING(@WhereClause, @IndexStart, @IndexEnd - @IndexStart+1)
							Set @Part3 = SUBSTRING(@WhereClause, @IndexEnd+1, LEN(@WhereClause))

							-- The replacement command is now in @Part2, for example: $Replace(MyLipidDataset,_Pos,)
							-- Split this command at the ( and , characters to allow us to perform the replacment
							
							Set @IndexStart = CHARINDEX('(', @Part2)
							Set @IndexEnd = CHARINDEX(',', @Part2, @IndexStart)				
							
							If @IndexStart > 0 And @IndexEnd > @IndexStart
							Begin -- <i2>
								
								-- We have determined the text to search
								Set @TextToSearch = SUBSTRING(@Part2, @IndexStart+1, @IndexEnd - @IndexStart-1)
								
								Set @IndexStart = @IndexEnd + 1
								Set @IndexEnd = CHARINDEX(',', @Part2, @IndexStart)		
								
								If @IndexEnd > @IndexStart
								Begin -- <j>
									-- We have determined the text to match
									Set @TextToFind =  SUBSTRING(@Part2, @IndexStart, @IndexEnd - @IndexStart)
								
									Set @IndexStart = @IndexEnd + 1
									Set @IndexEnd = CHARINDEX(')', @Part2, @IndexStart)		
									
									If @IndexEnd >= @IndexStart
									Begin -- <k>
										-- We have determined the replacement text
										Set @Replacement = SUBSTRING(@Part2, @IndexStart, @IndexEnd - @IndexStart)
								
										-- Make sure the text doesn't have any single quotes
										-- This would be the case if @SpecialProcessingText originally contained "$Replace($ThisDataset,"_Pos","")%NEG"}'
										Set @TextToFind = REPLACE(@TextToFind, '''', '')
										Set @Replacement = REPLACE(@Replacement, '''', '')
										--select @part2, '[' + @TextToSearch + ']', '[' + @TextToFind + ']', '[' + @Replacement + ']'

										Set @Part2 = REPLACE(@TextToSearch, @TextToFind, @Replacement)
										--select @Part2
										
										Set @WhereClause = @Part1 + @Part2 + @Part3
									End -- <k>

								End -- <j>
							End -- <i2>							
						End -- <h2>
						
					End -- </g2>

					
					-- By default, order by Job Descending
					-- However, if @WhereClause already contains ORDER BY then we don't want to add another one
					If @WhereClause LIKE '%ORDER BY%'
						Set @OrderBy = ''
					Else
						Set @OrderBy = 'ORDER BY Job Desc'
					
					-- Note that S_DMS_V_Analysis_Job_Info uses V_Source_Analysis_Job in DMS
					Set @AutoQuerySql = 'SELECT TOP 1 @SourceJob=Job FROM S_DMS_V_Analysis_Job_Info ' + @WhereClause + ' ' + @OrderBy
					
					Set @sqlParams = '@SourceJob int output'
					
					If @PreviewSql <> 0
						Print @AutoQuerySql

					exec sp_executesql @AutoQuerySql, @sqlParams, @SourceJob = @SourceJob output
					
					If @SourceJob = 0
					Begin
						Set @WarningMessage = 'Unable to determine SourceJob for job ' + Convert(varchar(12), @Job) + ' using query ' + @AutoQuerySql
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
			Set @WarningMessage = 'Query for SourceJob determination for job ' + Convert(varchar(12), @Job) + ': ' + @AutoQuerySql
			execute PostLogEntry 'Debug', @WarningMessage, 'LookupSourceJobFromSpecialProcessingText'
		End
		
		If @WarningMessage = ''
			Set @WarningMessage = 'Exception while determining SourceJob and/or results folder'
			
	End Catch	

	return @myError

GO
