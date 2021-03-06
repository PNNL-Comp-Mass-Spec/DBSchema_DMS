/****** Object:  Table [dbo].[T_MaxQuant_Mod_Residues] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MaxQuant_Mod_Residues](
	[Mod_ID] [int] NOT NULL,
	[Residue_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_MaxQuant_Mod_Residues] PRIMARY KEY CLUSTERED 
(
	[Mod_ID] ASC,
	[Residue_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_MaxQuant_Mod_Residues]  WITH CHECK ADD  CONSTRAINT [FK_T_MaxQuant_Mod_Residues_T_MaxQuant_Mods] FOREIGN KEY([Mod_ID])
REFERENCES [dbo].[T_MaxQuant_Mods] ([Mod_ID])
GO
ALTER TABLE [dbo].[T_MaxQuant_Mod_Residues] CHECK CONSTRAINT [FK_T_MaxQuant_Mod_Residues_T_MaxQuant_Mods]
GO
