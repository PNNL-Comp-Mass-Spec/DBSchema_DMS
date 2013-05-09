/****** Object:  Table [dbo].[T_Param_Entries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Param_Entries](
	[Param_Entry_ID] [int] IDENTITY(1000,1) NOT NULL,
	[Entry_Sequence_Order] [int] NULL,
	[Entry_Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entry_Specifier] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entry_Value] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Param_File_ID] [int] NOT NULL,
	[Entered] [datetime] NULL,
	[Entered_By] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Param_Entries] PRIMARY KEY CLUSTERED 
(
	[Param_Entry_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Trigger [dbo].[trig_d_T_Param_Entries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[trig_d_T_Param_Entries] ON [dbo].[T_Param_Entries] 
FOR DELETE
AS
/****************************************************
**
**	Desc: 
**		Updates Date_Modified in T_Param_Files
**
**	Auth: 	mem
**	Date: 	10/12/2007 (Ticket:557)
**    
*****************************************************/
	
	If @@RowCount = 0
		Return

	UPDATE T_Param_Files
	SET Date_Modified = GetDate()
	FROM T_Param_Files P INNER JOIN
		 deleted ON P.Param_File_ID = deleted.Param_File_ID



GO
/****** Object:  Trigger [dbo].[trig_i_T_Param_Entries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[trig_i_T_Param_Entries] ON [dbo].[T_Param_Entries] 
FOR INSERT
AS
/****************************************************
**
**	Desc: 
**		Updates Date_Modified in T_Param_Files
**
**	Auth:	mem
**	Date:	10/12/2007 (Ticket:557)
**    
*****************************************************/
	
	If @@RowCount = 0
		Return

	UPDATE T_Param_Files
	SET Date_Modified = GetDate()
	FROM T_Param_Files P INNER JOIN
		 inserted ON P.Param_File_ID = inserted.Param_File_ID



GO
/****** Object:  Trigger [dbo].[trig_u_T_Param_Entries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[trig_u_T_Param_Entries] ON [dbo].[T_Param_Entries] 
FOR UPDATE
AS
/****************************************************
**
**	Desc: 
**		Updates the Entered_By field if any of the fields are changed
**		Also updates Date_Modified in T_Param_Files
**
**	Auth:	 mem
**	Date: 	10/12/2007 (Ticket:557)
**    
*****************************************************/
	
	If @@RowCount = 0
		Return

	If Update(Entry_Sequence_Order) OR
	   Update(Entry_Type) OR
	   Update(Entry_Specifier) OR
       Update(Entry_Value) OR
       Update(Param_File_ID)
	Begin -- <a>
		
		Declare @TimeStamp datetime
		Set @TimeStamp = GetDate()

		-- Update Date_Modified in T_Param_Files for the Param_File_ID 
		--  values in the changed rows
		UPDATE T_Param_Files
		SET Date_Modified = @TimeStamp
		FROM T_Param_Files P INNER JOIN
			 inserted ON P.Param_File_ID = inserted.Param_File_ID

		If Update(Param_File_ID)
		Begin -- <b>
			-- Param_File_ID was changed; update Date_Modified in T_Param_Files 
			--  for the old Param_File_ID associated with the changed entries

			UPDATE T_Param_Files
			SET Date_Modified = @TimeStamp
			FROM T_Param_Files P INNER JOIN
				 deleted ON P.Param_File_ID = deleted.Param_File_ID
		End -- </b>

		-- Append the current time and username to the Entered_By field
		-- Note that dbo.udfTimeStampText returns a timestamp 
		-- in the form: 2006-09-01 09:05:03

		Declare @SepChar varchar(2)
		set @SepChar = ' ('

		Declare @UserInfo varchar(128)
		Set @UserInfo = dbo.udfTimeStampText(@TimeStamp) + '; ' + LEFT(SYSTEM_USER,75)
		Set @UserInfo = IsNull(@UserInfo, '')

		UPDATE T_Param_Entries
		SET Entered_By = CASE WHEN LookupQ.MatchLoc > 0 THEN Left(T_Param_Entries.Entered_By, LookupQ.MatchLoc-1) + @SepChar + @UserInfo + ')'
						 WHEN T_Param_Entries.Entered_By IS NULL Then SYSTEM_USER
						 ELSE IsNull(T_Param_Entries.Entered_By, '??') + @SepChar + @UserInfo + ')'
						 END
		FROM T_Param_Entries INNER JOIN 
			    (SELECT Param_Entry_ID, CharIndex(@SepChar, IsNull(Entered_By, '')) AS MatchLoc
				 FROM inserted 
				) LookupQ ON T_Param_Entries.Param_Entry_ID = LookupQ.Param_Entry_ID

	End -- </a>


GO
GRANT DELETE ON [dbo].[T_Param_Entries] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Param_Entries] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Param_Entries] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Param_Entries] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Param_Entries] ([Entered_By]) TO [DMS2_SP_User] AS [dbo]
GO
ALTER TABLE [dbo].[T_Param_Entries]  WITH CHECK ADD  CONSTRAINT [FK_T_Param_Entries_T_Param_Files] FOREIGN KEY([Param_File_ID])
REFERENCES [T_Param_Files] ([Param_File_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Param_Entries] CHECK CONSTRAINT [FK_T_Param_Entries_T_Param_Files]
GO
ALTER TABLE [dbo].[T_Param_Entries] ADD  CONSTRAINT [DF_T_Param_Entries_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Param_Entries] ADD  CONSTRAINT [DF_T_Param_Entries_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
