/****** Object:  Table [dbo].[T_Organism_DB_File] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Organism_DB_File](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[FileName] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Organism_ID] [int] NOT NULL,
	[Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Active] [tinyint] NOT NULL,
	[NumProteins] [int] NULL,
	[NumResidues] [bigint] NULL,
	[Valid] [smallint] NULL,
	[OrgFile_RowVersion] [timestamp] NOT NULL,
 CONSTRAINT [PK_T_Organism_DB_File] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY],
 CONSTRAINT [IX_T_Organism_DB_File] UNIQUE NONCLUSTERED 
(
	[FileName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT INSERT ON [dbo].[T_Organism_DB_File] TO [DMS_Limited_Organism_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Organism_DB_File] TO [DMS_Limited_Organism_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Organism_DB_File] TO [DMS_Limited_Organism_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[T_Organism_DB_File] TO [DMS_Limited_Organism_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Organism_DB_File] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Organism_DB_File] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Organism_DB_File] TO [Limited_Table_Write] AS [dbo]
GO
ALTER TABLE [dbo].[T_Organism_DB_File] ADD  CONSTRAINT [DF_T_Organism_DB_File_Description]  DEFAULT ('') FOR [Description]
GO
ALTER TABLE [dbo].[T_Organism_DB_File] ADD  CONSTRAINT [DF_T_Organism_DB_File_Active]  DEFAULT (1) FOR [Active]
GO
ALTER TABLE [dbo].[T_Organism_DB_File] ADD  CONSTRAINT [DF_T_Organism_DB_File_Valid]  DEFAULT (1) FOR [Valid]
GO
ALTER TABLE [dbo].[T_Organism_DB_File]  WITH CHECK ADD  CONSTRAINT [FK_T_Organism_DB_File_T_Organisms] FOREIGN KEY([Organism_ID])
REFERENCES [dbo].[T_Organisms] ([Organism_ID])
GO
ALTER TABLE [dbo].[T_Organism_DB_File] CHECK CONSTRAINT [FK_T_Organism_DB_File_T_Organisms]
GO
