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
	[Contents] [xml] NULL,
	[Job_Usage_Count] [int] NULL,
	[HMS_AutoSupersede] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MSGFPlus_AutoCentroid] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NULL,
	[Last_Updated] [datetime] NULL,
	[Job_Usage_Last_Year] [int] NULL,
 CONSTRAINT [PK_T_Settings_Files] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Settings_Files] TO [DDL_Viewer] AS [dbo]
GO
GRANT DELETE ON [dbo].[T_Settings_Files] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Settings_Files] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Settings_Files] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Settings_Files] TO [Limited_Table_Write] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Settings_Files_Analysis_Tool_File_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Settings_Files_Analysis_Tool_File_Name] ON [dbo].[T_Settings_Files]
(
	[Analysis_Tool] ASC,
	[File_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Settings_Files_File_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_Settings_Files_File_Name] ON [dbo].[T_Settings_Files]
(
	[File_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Settings_Files] ADD  CONSTRAINT [DF_T_Settings_Files_Description]  DEFAULT ('') FOR [Description]
GO
ALTER TABLE [dbo].[T_Settings_Files] ADD  CONSTRAINT [DF_T_Settings_Files_Active]  DEFAULT ((1)) FOR [Active]
GO
ALTER TABLE [dbo].[T_Settings_Files] ADD  CONSTRAINT [DF_T_Settings_Files_Job_Usage_Count]  DEFAULT ((0)) FOR [Job_Usage_Count]
GO
ALTER TABLE [dbo].[T_Settings_Files] ADD  CONSTRAINT [DF_T_Settings_Files_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_Settings_Files] ADD  CONSTRAINT [DF_T_Settings_Files_Last_Updated]  DEFAULT (getdate()) FOR [Last_Updated]
GO
ALTER TABLE [dbo].[T_Settings_Files] ADD  CONSTRAINT [DF_T_Settings_Files_Job_Usage_Last_Year]  DEFAULT ((0)) FOR [Job_Usage_Last_Year]
GO
ALTER TABLE [dbo].[T_Settings_Files]  WITH CHECK ADD  CONSTRAINT [FK_T_Settings_Files_T_Analysis_Tool] FOREIGN KEY([Analysis_Tool])
REFERENCES [dbo].[T_Analysis_Tool] ([AJT_toolName])
GO
ALTER TABLE [dbo].[T_Settings_Files] CHECK CONSTRAINT [FK_T_Settings_Files_T_Analysis_Tool]
GO
ALTER TABLE [dbo].[T_Settings_Files]  WITH CHECK ADD  CONSTRAINT [CK_T_Settings_Files_SettingsFileName_WhiteSpace] CHECK  (([dbo].[has_whitespace_chars]([File_Name],(0))=(0)))
GO
ALTER TABLE [dbo].[T_Settings_Files] CHECK CONSTRAINT [CK_T_Settings_Files_SettingsFileName_WhiteSpace]
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
ALTER TABLE [dbo].[T_Settings_Files] ENABLE TRIGGER [trig_d_T_Settings_Files]
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
ALTER TABLE [dbo].[T_Settings_Files] ENABLE TRIGGER [trig_i_T_Settings_Files]
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
**			03/30/2015 mem - Now validating MSGFPlus_AutoCentroid
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	If Update(HMS_AutoSupersede) OR Update(MSGFPlus_AutoCentroid)
	Begin
		-- Make sure a valid name was entered into the HMS_AutoSupersede and MSGFPlus_AutoCentroid fields
		Declare @UpdatedSettingsFileName varchar(255) = ''
		Declare @NewAutoSupersedeName varchar(255) = ''
		Declare @NewAutoCentroidName varchar(255) = ''
		Declare @message varchar(512)

		SELECT TOP 1 @UpdatedSettingsFileName = I.File_Name,
		             @NewAutoSupersedeName = I.HMS_AutoSupersede
		FROM inserted I
		     LEFT OUTER JOIN T_Settings_Files SF
		       ON I.HMS_AutoSupersede = SF.File_Name AND
		          I.Analysis_Tool = SF.Analysis_Tool
		WHERE NOT I.HMS_AutoSupersede IS NULL
		      AND SF.File_Name IS NULL
		
		If ISNULL(@UpdatedSettingsFileName, '') <> ''
		Begin
			Set @message = 'HMS_AutoSupersede value of ' + ISNULL(@NewAutoSupersedeName, '??') + ' is not valid for ' + ISNULL(@UpdatedSettingsFileName, '???') + ' in T_Settings_Files (see trigger trig_u_T_Settings_Files)'
			
			RAISERROR(@message,16,1)
	        ROLLBACK TRANSACTION
		    RETURN
		End

		Set @UpdatedSettingsFileName = ''

		SELECT TOP 1 @UpdatedSettingsFileName = I.File_Name,
		             @NewAutoCentroidName = I.MSGFPlus_AutoCentroid
		FROM inserted I
		     LEFT OUTER JOIN T_Settings_Files SF
		       ON I.MSGFPlus_AutoCentroid = SF.File_Name AND
		          I.Analysis_Tool = SF.Analysis_Tool
		WHERE NOT I.MSGFPlus_AutoCentroid IS NULL
		      AND SF.File_Name IS NULL

		If ISNULL(@UpdatedSettingsFileName, '') <> ''
		Begin
			Set @message = 'MSGFPlus_AutoCentroid value of ' + ISNULL(@NewAutoCentroidName, '??') + ' is not valid for ' + ISNULL(@UpdatedSettingsFileName, '???') + ' in T_Settings_Files (see trigger trig_u_T_Settings_Files)'
			
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
ALTER TABLE [dbo].[T_Settings_Files] ENABLE TRIGGER [trig_u_T_Settings_Files]
GO
