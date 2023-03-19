/****** Object:  Table [dbo].[T_Spectral_Library] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Spectral_Library](
	[Library_ID] [int] IDENTITY(1000,1) NOT NULL,
	[Library_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Library_State_ID] [int] NOT NULL,
	[Last_Affected] [datetime] NOT NULL,
	[Library_Type_ID] [int] NOT NULL,
	[Created] [datetime] NOT NULL,
	[Source_Job] [int] NULL,
	[Comment] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Storage_Path] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Protein_Collection_List] [varchar](2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Organism_DB_File] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Fragment_Ion_Mz_Min] [real] NOT NULL,
	[Fragment_Ion_Mz_Max] [real] NOT NULL,
	[Trim_N_Terminal_Met] [tinyint] NOT NULL,
	[Cleavage_Specificity] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Missed_Cleavages] [int] NOT NULL,
	[Peptide_Length_Min] [tinyint] NOT NULL,
	[Peptide_Length_Max] [tinyint] NOT NULL,
	[Precursor_Mz_Min] [real] NOT NULL,
	[Precursor_Mz_Max] [real] NOT NULL,
	[Precursor_Charge_Min] [tinyint] NOT NULL,
	[Precursor_Charge_Max] [tinyint] NOT NULL,
	[Static_Cys_Carbamidomethyl] [tinyint] NOT NULL,
	[Static_Mods] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Dynamic_Mods] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Max_Dynamic_Mods] [tinyint] NOT NULL,
	[Settings_Hash] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Spectral_Library] PRIMARY KEY CLUSTERED 
(
	[Library_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Spectral_Library_Library_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Spectral_Library_Library_Name] ON [dbo].[T_Spectral_Library]
(
	[Library_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Spectral_Library_Settings_Hash] ******/
CREATE NONCLUSTERED INDEX [IX_T_Spectral_Library_Settings_Hash] ON [dbo].[T_Spectral_Library]
(
	[Settings_Hash] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_State_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Comment]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Server_Share]  DEFAULT ('') FOR [Storage_Path]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Protein_Collection_List]  DEFAULT ('na') FOR [Protein_Collection_List]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Organism_DB_Fil]  DEFAULT ('na') FOR [Organism_DB_File]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Fragment_Ion_Mz_Min]  DEFAULT ((0)) FOR [Fragment_Ion_Mz_Min]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Fragment_Ion_Mz_Max]  DEFAULT ((0)) FOR [Fragment_Ion_Mz_Max]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_rim_N_Terminal_Met]  DEFAULT ((0)) FOR [Trim_N_Terminal_Met]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_leavage_Specificity]  DEFAULT ('') FOR [Cleavage_Specificity]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Missed_Cleavages]  DEFAULT ((0)) FOR [Missed_Cleavages]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Peptide_Length_Min]  DEFAULT ((0)) FOR [Peptide_Length_Min]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Peptide_Length_Max]  DEFAULT ((0)) FOR [Peptide_Length_Max]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Precursor_Mz_Min]  DEFAULT ((0)) FOR [Precursor_Mz_Min]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Precursor_Mz_Max]  DEFAULT ((0)) FOR [Precursor_Mz_Max]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Precursor_Charge_Min]  DEFAULT ((0)) FOR [Precursor_Charge_Min]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Precursor_Charge_Max]  DEFAULT ((0)) FOR [Precursor_Charge_Max]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Static_Cys_Carbamidomethyl]  DEFAULT ((0)) FOR [Static_Cys_Carbamidomethyl]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Static_Mods]  DEFAULT ('') FOR [Static_Mods]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Dynamic_Mods]  DEFAULT ('') FOR [Dynamic_Mods]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Max_Dynamic_Mods]  DEFAULT ((0)) FOR [Max_Dynamic_Mods]
GO
ALTER TABLE [dbo].[T_Spectral_Library] ADD  CONSTRAINT [DF_T_Spectral_Library_Settings_Hash]  DEFAULT ('') FOR [Settings_Hash]
GO
ALTER TABLE [dbo].[T_Spectral_Library]  WITH CHECK ADD  CONSTRAINT [FK_T_Spectral_Library_T_Spectral_Library_State] FOREIGN KEY([Library_State_ID])
REFERENCES [dbo].[T_Spectral_Library_State] ([Library_State_ID])
GO
ALTER TABLE [dbo].[T_Spectral_Library] CHECK CONSTRAINT [FK_T_Spectral_Library_T_Spectral_Library_State]
GO
ALTER TABLE [dbo].[T_Spectral_Library]  WITH CHECK ADD  CONSTRAINT [FK_T_Spectral_Library_T_Spectral_Library_Type] FOREIGN KEY([Library_Type_ID])
REFERENCES [dbo].[T_Spectral_Library_Type] ([Library_Type_ID])
GO
ALTER TABLE [dbo].[T_Spectral_Library] CHECK CONSTRAINT [FK_T_Spectral_Library_T_Spectral_Library_Type]
GO
/****** Object:  Trigger [dbo].[trig_u_T_Spectral_Library] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[trig_u_T_Spectral_Library] ON [dbo].[T_Spectral_Library] 
FOR UPDATE
AS
/****************************************************
**
**	Desc: 
**		Updates Last_Affected if the State changes
**
**	Auth:	mem
**	Date:	03/18/2023 mem - Initial version
**    
*****************************************************/
	
	If @@RowCount = 0
		Return

	If Update(Library_State_ID)
	Begin
		UPDATE T_Spectral_Library
		SET Last_Affected = GetDate()
		FROM T_Spectral_Library INNER JOIN 
			 inserted ON T_Spectral_Library.Library_ID = inserted.Library_ID
	End


GO
ALTER TABLE [dbo].[T_Spectral_Library] ENABLE TRIGGER [trig_u_T_Spectral_Library]
GO
