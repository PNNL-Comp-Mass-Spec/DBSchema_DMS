/****** Object:  StoredProcedure [dbo].[UpdateDatasetFileInfoFromFile] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.UpdateDatasetFileInfoFromFile
/****************************************************
** 
**	############################################################################
**
**  ### NOTE: This procedure has been superseded by UpdateDatasetFileInfoXML ###
**
**  ############################################################################
**
**
**	Desc: Loads the Dataset info from a file (using bulk load)
**		  and updates T_Dataset with the information
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	mem
**	Date:	09/15/2005
**			08/27/2007 mem - Added support for a 9th column in the source file
**    
*****************************************************/
(
	@DatasetInfoFilePath varchar(255),
	@message varchar(255) = '' output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @fileExists tinyint
	Declare @columnCount int
	Declare @FirstRowPreview varchar(2048)
	Declare @FirstRowNum int
	
	declare @result int
	declare @NumLoaded int
	declare @UpdateCount int
	
	-----------------------------------------------------------
	-- Create the table to hold the data
	-----------------------------------------------------------


	If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[#Tmp_Dataset_Info]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
		drop table [dbo].[#Tmp_Dataset_Info]

	CREATE TABLE [dbo].[#Tmp_Dataset_Info] (
		[Dataset_ID] [int] NULL ,
		[Dataset_Name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
		[File_Extension] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
		[Acq_Time_Start] [datetime] NULL ,
		[Acq_Time_End] [datetime] NULL ,
		[Scan_Count] [int] NULL ,
		[File_Size_Bytes] [bigint] NULL ,
		[File_Info_Last_Modified] [datetime] NULL 
	)

	-----------------------------------------------
	-- Add index to temporary table to improve the 
	-- speed of the Update query
	-----------------------------------------------
	--
	CREATE NONCLUSTERED INDEX #IX_Tmp_Dataset_Info_DatasetName ON [dbo].[#Tmp_Dataset_Info] ([Dataset_Name])

	
	-----------------------------------------------
	-- Verify that input file exists, count the number of columns,
	-- and preview the first row
	-----------------------------------------------
	Exec @result = ValidateDelimitedFile @DatasetInfoFilePath, 0, @fileExists OUTPUT, @columnCount OUTPUT, @FirstRowPreview OUTPUT, @message OUTPUT
	
	If @result <> 0
	Begin
		If Len(@message) = 0
			Set @message = 'Error calling ValidateDelimitedFile for ' + @DatasetInfoFilePath + ' (Code ' + Convert(varchar(11), @result) + ')'
		
		Set @myError = 60001
		Goto Done
	End
	Else
	Begin
		If @columnCount < 8
		Begin
			If @columnCount = 0
			Begin
				Set @message = 'Dataset info file was empty'
				set @myError = 60002	-- Note that this error code is used in SP LoadResultsForAvailableAnalyses; do not change
			End
			Else
			Begin
				Set @message = 'Dataset info file only contains ' + convert(varchar(11), @columnCount) + ' columns (Expecting 8 or 9 columns)'
				set @myError = 60003
			End
			Goto Done
		end
		else
		Begin
			If @columnCount > 9
			Begin
				Set @message = 'Dataset info file contains ' + convert(varchar(11), @columnCount) + ' columns (Expecting 8 or 9 columns)'
				set @myError = 60003
				Goto Done
			End

			If @columnCount = 9
			Begin
				-- Add another column to [#Tmp_Dataset_Info]
				ALTER TABLE [dbo].[#Tmp_Dataset_Info]
				ADD [File_Modification_Date] [datetime] NULL
			End
		End

	End
	
	-----------------------------------------------
	-- See If @FirstRowPreview starts with a number
	-- If it does not, then skip the first row
	-----------------------------------------------
	
	If IsNumeric(SubString(@FirstRowPreview, 1, 1)) = 1
		Set @FirstRowNum = 1
	Else
		Set @FirstRowNum = 2

	-----------------------------------------------
	-- Bulk load contents of @DatasetInfoFilePath into 
	-- the temporary table
	-----------------------------------------------
	--
	declare @c nvarchar(255)

	Set @c = ''
	Set @c = @c + ' BULK INSERT dbo.#Tmp_Dataset_Info FROM ' + '''' + @DatasetInfoFilePath + ''''
	Set @c = @c + ' WITH (FIRSTROW = ' + Convert(varchar(9), @FirstRowNum) + ')'

	exec @result = sp_executesql @c
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	set @NumLoaded = @myRowCount
	--
	If @result <> 0
	Begin
		set @message = 'Problem executing bulk insert'
		goto Done
	end


	-----------------------------------------------
	-- Look for any entries in the temporary table
	-- where Acq_Time_Start is Null while Acq_Time_End is defined
	-----------------------------------------------
	
	UPDATE dbo.#Tmp_Dataset_Info
	SET Acq_Time_Start = Acq_Time_End
	WHERE Acq_Time_Start IS NULL AND NOT Acq_Time_End IS NULL
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	-- Now look for the reverse case
	--
	UPDATE dbo.#Tmp_Dataset_Info
	SET Acq_Time_End = Acq_Time_Start
	WHERE Acq_Time_End IS NULL AND NOT Acq_Time_Start IS NULL
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	
	-----------------------------------------------
	-- Update T_Dataset with any new or changed values
	-- If Acq_Time_Start Is Null or is <= 1/1/1900 then
	--  the DS_Created time is used for both 
	--  Acq_Time_Start and Acq_Time_End
	-----------------------------------------------
	
	UPDATE T_Dataset
	SET Acq_Time_Start= CASE WHEN IsNull(NewInfo.Acq_Time_Start, '1/1/1900') <= '1/1/1900'
						THEN DS.DS_Created 
						ELSE NewInfo.Acq_Time_Start END,
		Acq_Time_End =  CASE WHEN IsNull(NewInfo.Acq_Time_Start, '1/1/1900') <= '1/1/1900' 
						THEN DS.DS_Created 
						ELSE NewInfo.Acq_Time_End END,
		Scan_Count = NewInfo.Scan_Count, 
		File_Size_Bytes = NewInfo.File_Size_Bytes, 
		File_Info_Last_Modified = NewInfo.File_Info_Last_Modified
	FROM dbo.#Tmp_Dataset_Info NewInfo INNER JOIN T_Dataset DS ON 
		NewInfo.Dataset_Name = DS.Dataset_Num AND
		NewInfo.File_Info_Last_Modified > ISNULL(DS.File_Info_Last_Modified, '1/1/1900')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	Set @UpdateCount =  @myRowCount

		
	Set @message = 'Done: Updated ' + Convert(varchar(9), @UpdateCount) + ' datasets (out of ' + Convert(varchar(9), @NumLoaded) + ' in the Dataset Info File)'
	
Done:
	
	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateDatasetFileInfoFromFile] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetFileInfoFromFile] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetFileInfoFromFile] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetFileInfoFromFile] TO [PNL\D3M580] AS [dbo]
GO
