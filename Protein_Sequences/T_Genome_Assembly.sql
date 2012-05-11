/****** Object:  Table [dbo].[T_Genome_Assembly] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Genome_Assembly](
	[Assembly_ID] [int] IDENTITY(1,1) NOT NULL,
	[Source_File_Path] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Organism_ID] [int] NULL,
	[Authority_ID] [int] NULL,
 CONSTRAINT [PK_T_Genome_Assembly] PRIMARY KEY CLUSTERED 
(
	[Assembly_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Genome_Assembly]  WITH CHECK ADD  CONSTRAINT [FK_T_Genome_Assembly_T_Naming_Authorities] FOREIGN KEY([Authority_ID])
REFERENCES [T_Naming_Authorities] ([Authority_ID])
GO
ALTER TABLE [dbo].[T_Genome_Assembly] CHECK CONSTRAINT [FK_T_Genome_Assembly_T_Naming_Authorities]
GO
