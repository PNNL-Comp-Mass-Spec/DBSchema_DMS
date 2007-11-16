/****** Object:  Table [dbo].[T_Param_File_Mass_Mods] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Param_File_Mass_Mods](
	[Mod_Entry_ID] [int] IDENTITY(1000,1) NOT NULL,
	[Residue_ID] [int] NULL,
	[Local_Symbol_ID] [tinyint] NOT NULL,
	[Mass_Correction_ID] [int] NOT NULL,
	[Param_File_ID] [int] NULL,
	[Mod_Type_Symbol] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Peptide_Mod_Param_File_List_Ex] PRIMARY KEY CLUSTERED 
(
	[Mod_Entry_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_Param_File_Mass_Mods] TO [DMS_ParamFile_Admin]
GO
GRANT INSERT ON [dbo].[T_Param_File_Mass_Mods] TO [DMS_ParamFile_Admin]
GO
GRANT SELECT ON [dbo].[T_Param_File_Mass_Mods] TO [DMS_ParamFile_Admin]
GO
GRANT UPDATE ON [dbo].[T_Param_File_Mass_Mods] TO [DMS_ParamFile_Admin]
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods]  WITH CHECK ADD  CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Mass_Correction_Factors] FOREIGN KEY([Mass_Correction_ID])
REFERENCES [T_Mass_Correction_Factors] ([Mass_Correction_ID])
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods] CHECK CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Mass_Correction_Factors]
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods]  WITH CHECK ADD  CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Modification_Types] FOREIGN KEY([Mod_Type_Symbol])
REFERENCES [T_Modification_Types] ([Mod_Type_Symbol])
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods] CHECK CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Modification_Types]
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods]  WITH CHECK ADD  CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Param_Files] FOREIGN KEY([Param_File_ID])
REFERENCES [T_Param_Files] ([Param_File_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods] CHECK CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Param_Files]
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods]  WITH CHECK ADD  CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Residues] FOREIGN KEY([Residue_ID])
REFERENCES [T_Residues] ([Residue_ID])
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods] CHECK CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Residues]
GO
