/****** Object:  Table [dbo].[T_DNA_Structures] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_DNA_Structures](
	[DNA_Structure_ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DNA_Structure_Type_ID] [int] NULL,
	[DNA_Translation_Table_ID] [int] NULL,
	[Assembly_ID] [int] NULL,
 CONSTRAINT [PK_T_DNA_Structures] PRIMARY KEY CLUSTERED 
(
	[DNA_Structure_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_DNA_Structures]  WITH CHECK ADD  CONSTRAINT [FK_T_DNA_Structures_T_DNA_Structure_Types] FOREIGN KEY([DNA_Structure_Type_ID])
REFERENCES [dbo].[T_DNA_Structure_Types] ([DNA_Structure_Type_ID])
GO
ALTER TABLE [dbo].[T_DNA_Structures] CHECK CONSTRAINT [FK_T_DNA_Structures_T_DNA_Structure_Types]
GO
ALTER TABLE [dbo].[T_DNA_Structures]  WITH CHECK ADD  CONSTRAINT [FK_T_DNA_Structures_T_DNA_Translation_Table_Map] FOREIGN KEY([DNA_Translation_Table_ID])
REFERENCES [dbo].[T_DNA_Translation_Table_Map] ([DNA_Translation_Table_ID])
GO
ALTER TABLE [dbo].[T_DNA_Structures] CHECK CONSTRAINT [FK_T_DNA_Structures_T_DNA_Translation_Table_Map]
GO
ALTER TABLE [dbo].[T_DNA_Structures]  WITH CHECK ADD  CONSTRAINT [FK_T_DNA_Structures_T_Genome_Assembly] FOREIGN KEY([Assembly_ID])
REFERENCES [dbo].[T_Genome_Assembly] ([Assembly_ID])
GO
ALTER TABLE [dbo].[T_DNA_Structures] CHECK CONSTRAINT [FK_T_DNA_Structures_T_Genome_Assembly]
GO
