/****** Object:  Table [dbo].[T_Settings_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Settings_Files](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Analysis_Tool] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[File_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Active] [tinyint] NULL,
	[Last_Updated] [datetime] NULL,
	[Contents] [xml] NULL,
	[Job_Usage_Count] [int] NULL,
	[HMS_AutoSupersede] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Settings_Files] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Settings_Files_Analysis_Tool_File_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Settings_Files_Analysis_Tool_File_Name] ON [dbo].[T_Settings_Files] 
(
	[Analysis_Tool] ASC,
	[File_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Settings_Files_File_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_Settings_Files_File_Name] ON [dbo].[T_Settings_Files] 
(
	[File_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Trigger [dbo].[trig_d_T_Settings_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_d_T_Settings_Files] on [dbo].[T_Settings_Files]
For Delete
AS
	If @@RowCount = 0
		Return

	INSERT INTO T_Settings_Files_XML_History(
			Event_Action, ID, 
            Analysis_Tool, File_Name, 
			Description, Contents,
			Entered, Entered_By )
	SELECT 'Delete' AS Event_Action, ID, 
           Analysis_Tool, File_Name,
		   Description, Contents,
		   GetDate(), SYSTEM_USER
	FROM deleted

GO
/****** Object:  Trigger [dbo].[trig_i_T_Settings_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_i_T_Settings_Files] on [dbo].[T_Settings_Files]
For Insert
AS
	If @@RowCount = 0
		Return

	INSERT INTO T_Settings_Files_XML_History(
			Event_Action, ID, 
            Analysis_Tool, File_Name, 
			Description, Contents,
			Entered, Entered_By )
	SELECT 'Create' AS Event_Action, ID, 
           Analysis_Tool, File_Name,
	       Description, Contents,
	       GetDate(), SYSTEM_USER
	FROM inserted


GO
/****** Object:  Trigger [dbo].[trig_u_T_Settings_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_u_T_Settings_Files] on [dbo].[T_Settings_Files]
For Update
/****************************************************
**
**	Desc: 
**		Stores a copy of the XML file in T_Settings_Files_XML_History
**
**	Auth:	mem
**	Date:	10/07/2008 mem
**			11/05/2012 mem - Now validating HMS_AutoSupersede
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	If Update(HMS_AutoSupersede)
	Begin
		-- Make sure a valid name was entered into the HMS_AutoSupersede field
		Declare @UpdatedSettingsFileName varchar(255) = ''
		Declare @NewAutoSupersedeName varchar(255) = ''
		
		SELECT TOP 1 @UpdatedSettingsFileName = I.File_Name,
		             @NewAutoSupersedeName = I.HMS_AutoSupersede
		FROM inserted I
		     LEFT OUTER JOIN T_Settings_Files SF
		       ON I.HMS_AutoSupersede = SF.File_Name AND
		          I.Analysis_Tool = SF.Analysis_Tool
		WHERE I.HMS_AutoSupersede IS NOT NULL AND
		      SF.File_Name IS NULL
		
		If ISNULL(@UpdatedSettingsFileName, '') <> ''
		Begin
			Declare @message varchar(512)
			Set @message = 'HMS_AutoSupersede value of ' + ISNULL(@NewAutoSupersedeName, '??') + ' is not valid for ' + ISNULL(@UpdatedSettingsFileName, '???') + ' in T_Settings_Files (see trigger trig_u_T_Settings_Files)'
			
			RAISERROR(@message,16,1)
	        ROLLBACK TRANSACTION
		    RETURN
		End
	End

	If Update(Analysis_Tool) Or 
	   Update(File_Name) Or 
	   Update(Contents)
	Begin
		INSERT INTO T_Settings_Files_XML_History(
				Event_Action, ID, 
                Analysis_Tool, File_Name, 
				Description, Contents,
				Entered, Entered_By )
		SELECT 'Update' AS Event_Action, ID, 
               Analysis_Tool, File_Name,
			   Description, Contents,
			   GetDate(), SYSTEM_USER
		FROM inserted
	End
		

GO
GRANT DELETE ON [dbo].[T_Settings_Files] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Settings_Files] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Settings_Files] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Settings_Files] TO [Limited_Table_Write] AS [dbo]
GO
ALTER TABLE [dbo].[T_Settings_Files]  WITH CHECK ADD  CONSTRAINT [FK_T_Settings_Files_T_Analysis_Tool] FOREIGN KEY([Analysis_Tool])
REFERENCES [T_Analysis_Tool] ([AJT_toolName])
GO
ALTER TABLE [dbo].[T_Settings_Files] CHECK CONSTRAINT [FK_T_Settings_Files_T_Analysis_Tool]
GO
ALTER TABLE [dbo].[T_Settings_Files]  WITH CHECK ADD  CONSTRAINT [CK_T_Settings_Files_SettingsFileName_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([File_Name],(0))=(0)))
GO
ALTER TABLE [dbo].[T_Settings_Files] CHECK CONSTRAINT [CK_T_Settings_Files_SettingsFileName_WhiteSpace]
GO
ALTER TABLE [dbo].[T_Settings_Files] ADD  CONSTRAINT [DF_T_Settings_Files_Description]  DEFAULT ('') FOR [Description]
GO
ALTER TABLE [dbo].[T_Settings_Files] ADD  CONSTRAINT [DF_T_Settings_Files_Active]  DEFAULT ((1)) FOR [Active]
GO
ALTER TABLE [dbo].[T_Settings_Files] ADD  CONSTRAINT [DF_T_Settings_Files_Last_Updated]  DEFAULT (getdate()) FOR [Last_Updated]
GO
ALTER TABLE [dbo].[T_Settings_Files] ADD  CONSTRAINT [DF_T_Settings_Files_Job_Usage_Count]  DEFAULT ((0)) FOR [Job_Usage_Count]
GO
