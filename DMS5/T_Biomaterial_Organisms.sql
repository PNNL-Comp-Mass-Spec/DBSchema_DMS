/****** Object:  Table [dbo].[T_Biomaterial_Organisms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Biomaterial_Organisms](
	[Biomaterial_ID] [int] NOT NULL,
	[Organism_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Biomaterial_Organisms] PRIMARY KEY CLUSTERED 
(
	[Organism_ID] ASC,
	[Biomaterial_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Biomaterial_Organisms]  WITH CHECK ADD  CONSTRAINT [FK_T_Biomaterial_Organisms_T_Cell_Culture] FOREIGN KEY([Biomaterial_ID])
REFERENCES [dbo].[T_Cell_Culture] ([CC_ID])
GO
ALTER TABLE [dbo].[T_Biomaterial_Organisms] CHECK CONSTRAINT [FK_T_Biomaterial_Organisms_T_Cell_Culture]
GO
ALTER TABLE [dbo].[T_Biomaterial_Organisms]  WITH CHECK ADD  CONSTRAINT [FK_T_Biomaterial_Organisms_T_Organisms] FOREIGN KEY([Organism_ID])
REFERENCES [dbo].[T_Organisms] ([Organism_ID])
GO
ALTER TABLE [dbo].[T_Biomaterial_Organisms] CHECK CONSTRAINT [FK_T_Biomaterial_Organisms_T_Organisms]
GO
