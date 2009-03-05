/****** Object:  Table [dbo].[T_Organism_DB_File] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Organism_DB_File](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[FileName] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Organism_ID] [int] NOT NULL,
	[Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Organism_DB_File_Description]  DEFAULT (''),
	[Active] [tinyint] NOT NULL CONSTRAINT [DF_T_Organism_DB_File_Active]  DEFAULT (1),
	[NumProteins] [int] NULL,
	[NumResidues] [bigint] NULL,
	[Valid] [smallint] NULL CONSTRAINT [DF_T_Organism_DB_File_Valid]  DEFAULT (1),
 CONSTRAINT [PK_T_Organism_DB_File] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_T_Organism_DB_File] UNIQUE NONCLUSTERED 
(
	[FileName] ASC,
	[Organism_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT INSERT ON [dbo].[T_Organism_DB_File] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organism_DB_File] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organism_DB_File] TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Organism_DB_File]  WITH CHECK ADD  CONSTRAINT [FK_T_Organism_DB_File_T_Organisms] FOREIGN KEY([Organism_ID])
REFERENCES [T_Organisms] ([Organism_ID])
GO
